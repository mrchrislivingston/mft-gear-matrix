import 'garmin_mobile_client.dart';

typedef GarminCalendarMonthLoader =
    Future<List<GarminScheduledWorkout>> Function({
      required int year,
      required int month,
    });

typedef GarminWorkoutUploader =
    Future<GarminUploadedWorkout> Function(Map<String, dynamic> payload);

typedef GarminWorkoutScheduler =
    Future<Map<String, dynamic>> Function({
      required int workoutId,
      required String date,
    });

typedef GarminWorkoutDeleter = Future<void> Function(int workoutId);

enum GarminImportDisposition { ready, exactDuplicate, dateConflict }

enum GarminImportResultStatus {
  scheduled,
  skippedDuplicate,
  blockedConflict,
  failed,
}

class GarminImportWorkout {
  final String candidateId;
  final String date;
  final Map<String, dynamic> payload;

  GarminImportWorkout({
    required this.candidateId,
    required this.date,
    required Map<String, dynamic> payload,
  }) : payload = Map.unmodifiable(payload);

  String get workoutName {
    return payload['workoutName']?.toString().trim() ?? '';
  }
}

class GarminImportPlanItem {
  final GarminImportWorkout workout;
  final GarminImportDisposition disposition;
  final List<GarminScheduledWorkout> existingWorkouts;

  const GarminImportPlanItem({
    required this.workout,
    required this.disposition,
    required this.existingWorkouts,
  });
}

class GarminImportPlan {
  final List<GarminImportPlanItem> items;

  GarminImportPlan(List<GarminImportPlanItem> items)
    : items = List.unmodifiable(items);

  List<GarminImportPlanItem> get readyItems {
    return items
        .where((item) => item.disposition == GarminImportDisposition.ready)
        .toList(growable: false);
  }

  bool get hasBlockingConflicts {
    return items.any(
      (item) => item.disposition == GarminImportDisposition.dateConflict,
    );
  }
}

class GarminImportResult {
  final GarminImportWorkout workout;
  final GarminImportResultStatus status;
  final int? workoutId;
  final String message;

  const GarminImportResult({
    required this.workout,
    required this.status,
    required this.workoutId,
    required this.message,
  });
}

class GarminWorkoutImportService {
  final GarminCalendarMonthLoader calendarLoader;
  final GarminWorkoutUploader uploader;
  final GarminWorkoutScheduler scheduler;
  final GarminWorkoutDeleter deleter;

  const GarminWorkoutImportService({
    required this.calendarLoader,
    required this.uploader,
    required this.scheduler,
    required this.deleter,
  });

  factory GarminWorkoutImportService.forClient(GarminMobileClient client) {
    return GarminWorkoutImportService(
      calendarLoader: client.getScheduledWorkoutsForMonth,
      uploader: client.uploadWorkout,
      scheduler: client.scheduleWorkout,
      deleter: client.deleteWorkout,
    );
  }

  Future<GarminImportPlan> preflight(List<GarminImportWorkout> workouts) async {
    final candidateIds = <String>{};
    final months = <String, (int, int)>{};

    for (final workout in workouts) {
      _validateWorkout(workout);

      if (!candidateIds.add(workout.candidateId)) {
        throw GarminMobileException(
          'Duplicate import candidate ID: ${workout.candidateId}',
        );
      }

      final date = DateTime.parse(workout.date);
      months['${date.year}-${date.month}'] = (date.year, date.month);
    }

    final scheduled = <GarminScheduledWorkout>[];

    for (final month in months.values) {
      scheduled.addAll(await calendarLoader(year: month.$1, month: month.$2));
    }

    return GarminImportPlan(
      workouts
          .map((workout) {
            return _planItem(workout, scheduled);
          })
          .toList(growable: false),
    );
  }

  Future<List<GarminImportResult>> commit(
    GarminImportPlan plan, {
    required bool confirmed,
  }) async {
    if (!confirmed) {
      throw const GarminMobileException(
        'Garmin import requires explicit confirmation.',
      );
    }

    final results = <GarminImportResult>[];

    for (final planned in plan.items) {
      if (planned.disposition == GarminImportDisposition.exactDuplicate) {
        results.add(
          GarminImportResult(
            workout: planned.workout,
            status: GarminImportResultStatus.skippedDuplicate,
            workoutId: null,
            message: 'Already scheduled on Garmin.',
          ),
        );
        continue;
      }

      if (planned.disposition == GarminImportDisposition.dateConflict) {
        results.add(
          GarminImportResult(
            workout: planned.workout,
            status: GarminImportResultStatus.blockedConflict,
            workoutId: null,
            message: 'Another workout is scheduled on this date.',
          ),
        );
        continue;
      }

      final date = DateTime.parse(planned.workout.date);

      // Recheck immediately before writing to avoid stale preflight data.
      final currentSchedule = await calendarLoader(
        year: date.year,
        month: date.month,
      );
      final currentPlan = _planItem(planned.workout, currentSchedule);

      if (currentPlan.disposition == GarminImportDisposition.exactDuplicate) {
        results.add(
          GarminImportResult(
            workout: planned.workout,
            status: GarminImportResultStatus.skippedDuplicate,
            workoutId: null,
            message: 'Already scheduled on Garmin.',
          ),
        );
        continue;
      }

      if (currentPlan.disposition == GarminImportDisposition.dateConflict) {
        results.add(
          GarminImportResult(
            workout: planned.workout,
            status: GarminImportResultStatus.blockedConflict,
            workoutId: null,
            message: 'A workout appeared on this date after preview.',
          ),
        );
        continue;
      }

      GarminUploadedWorkout? uploaded;

      try {
        uploaded = await uploader(planned.workout.payload);

        await scheduler(
          workoutId: uploaded.workoutId,
          date: planned.workout.date,
        );

        results.add(
          GarminImportResult(
            workout: planned.workout,
            status: GarminImportResultStatus.scheduled,
            workoutId: uploaded.workoutId,
            message: 'Uploaded and scheduled on Garmin.',
          ),
        );
      } on Object {
        if (uploaded == null) {
          results.add(
            GarminImportResult(
              workout: planned.workout,
              status: GarminImportResultStatus.failed,
              workoutId: null,
              message: 'Garmin workout upload failed.',
            ),
          );
          continue;
        }

        var cleanedUp = false;

        try {
          await deleter(uploaded.workoutId);
          cleanedUp = true;
        } on Object {
          cleanedUp = false;
        }

        results.add(
          GarminImportResult(
            workout: planned.workout,
            status: GarminImportResultStatus.failed,
            workoutId: uploaded.workoutId,
            message: cleanedUp
                ? 'Scheduling failed; the uploaded workout was removed.'
                : 'Scheduling failed; uploaded workout '
                      '${uploaded.workoutId} may remain in Garmin.',
          ),
        );
      }
    }

    return List.unmodifiable(results);
  }

  GarminImportPlanItem _planItem(
    GarminImportWorkout workout,
    List<GarminScheduledWorkout> scheduled,
  ) {
    final sameDate = scheduled
        .where((item) => item.date == workout.date)
        .toList(growable: false);

    final exact = sameDate.any(
      (item) => item.title.trim() == workout.workoutName,
    );

    final disposition = exact
        ? GarminImportDisposition.exactDuplicate
        : sameDate.isNotEmpty
        ? GarminImportDisposition.dateConflict
        : GarminImportDisposition.ready;

    return GarminImportPlanItem(
      workout: workout,
      disposition: disposition,
      existingWorkouts: List.unmodifiable(sameDate),
    );
  }

  void _validateWorkout(GarminImportWorkout workout) {
    if (workout.candidateId.trim().isEmpty) {
      throw const GarminMobileException(
        'Garmin import candidate ID is missing.',
      );
    }

    if (workout.workoutName.isEmpty) {
      throw const GarminMobileException('Garmin workout name is missing.');
    }

    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(workout.date);

    if (match == null) {
      throw const GarminMobileException(
        'Garmin workout date must use YYYY-MM-DD.',
      );
    }

    final parsed = DateTime.tryParse(workout.date);
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    if (parsed == null ||
        parsed.year != year ||
        parsed.month != month ||
        parsed.day != day) {
      throw const GarminMobileException('Garmin workout date is invalid.');
    }

    final segments = workout.payload['workoutSegments'];

    if (segments is! List || segments.isEmpty) {
      throw const GarminMobileException(
        'Garmin workout payload has no segments.',
      );
    }
  }
}
