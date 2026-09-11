import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/garmin_mobile_client.dart';
import 'package:mft_gear_matrix/services/garmin_workout_import_service.dart';

GarminImportWorkout importWorkout({
  String candidateId = 'candidate-1',
  String date = '2026-09-16',
  String name = 'G1 C2 Bike - 2026-09-16',
}) {
  return GarminImportWorkout(
    candidateId: candidateId,
    date: date,
    payload: {
      'workoutName': name,
      'workoutSegments': [
        {
          'workoutSteps': [
            {'stepOrder': 1},
          ],
        },
      ],
    },
  );
}

GarminScheduledWorkout scheduledWorkout({
  int scheduleId = 100,
  int workoutId = 200,
  String date = '2026-09-16',
  String title = 'G1 C2 Bike - 2026-09-16',
}) {
  return GarminScheduledWorkout(
    scheduleId: scheduleId,
    workoutId: workoutId,
    title: title,
    date: date,
    sportTypeKey: 'cycling',
  );
}

void main() {
  test('preflight distinguishes ready, duplicate, and conflict', () async {
    final service = GarminWorkoutImportService(
      calendarLoader: ({required year, required month}) async {
        expect(year, 2026);
        expect(month, 9);

        return [
          scheduledWorkout(),
          scheduledWorkout(
            scheduleId: 101,
            workoutId: 201,
            date: '2026-09-17',
            title: 'Different Garmin Workout',
          ),
        ];
      },
      uploader: (_) async => throw UnimplementedError(),
      scheduler: ({required workoutId, required date}) async =>
          throw UnimplementedError(),
      deleter: (_) async => throw UnimplementedError(),
    );

    final plan = await service.preflight([
      importWorkout(),
      importWorkout(
        candidateId: 'candidate-2',
        date: '2026-09-17',
        name: 'G2 Row - 2026-09-17',
      ),
      importWorkout(
        candidateId: 'candidate-3',
        date: '2026-09-18',
        name: 'P1 Row - 2026-09-18',
      ),
    ]);

    expect(plan.items.map((item) => item.disposition).toList(), [
      GarminImportDisposition.exactDuplicate,
      GarminImportDisposition.dateConflict,
      GarminImportDisposition.ready,
    ]);
    expect(plan.readyItems, hasLength(1));
    expect(plan.hasBlockingConflicts, isTrue);
  });

  test('commit requires explicit confirmation', () async {
    var uploads = 0;

    final service = GarminWorkoutImportService(
      calendarLoader: ({required year, required month}) async => [],
      uploader: (_) async {
        uploads++;
        return const GarminUploadedWorkout(workoutId: 300, workoutName: 'Test');
      },
      scheduler: ({required workoutId, required date}) async => {},
      deleter: (_) async {},
    );

    final plan = await service.preflight([importWorkout()]);

    expect(
      () => service.commit(plan, confirmed: false),
      throwsA(isA<GarminMobileException>()),
    );
    expect(uploads, 0);
  });

  test('rechecks calendar immediately before upload and schedule', () async {
    var calendarChecks = 0;
    var uploads = 0;
    var schedules = 0;

    final service = GarminWorkoutImportService(
      calendarLoader: ({required year, required month}) async {
        calendarChecks++;
        return [];
      },
      uploader: (payload) async {
        uploads++;
        return GarminUploadedWorkout(
          workoutId: 300,
          workoutName: payload['workoutName'] as String,
        );
      },
      scheduler: ({required workoutId, required date}) async {
        schedules++;
        expect(workoutId, 300);
        expect(date, '2026-09-16');
        return {'id': 400};
      },
      deleter: (_) async {},
    );

    final plan = await service.preflight([importWorkout()]);
    final results = await service.commit(plan, confirmed: true);

    expect(calendarChecks, 2);
    expect(uploads, 1);
    expect(schedules, 1);
    expect(results.single.status, GarminImportResultStatus.scheduled);
    expect(results.single.workoutId, 300);
  });

  test('blocks a workout that appears after preflight', () async {
    var calendarChecks = 0;
    var uploads = 0;

    final service = GarminWorkoutImportService(
      calendarLoader: ({required year, required month}) async {
        calendarChecks++;

        if (calendarChecks == 1) {
          return [];
        }

        return [scheduledWorkout(title: 'Workout Added From Another Device')];
      },
      uploader: (_) async {
        uploads++;
        return const GarminUploadedWorkout(
          workoutId: 300,
          workoutName: 'Unexpected',
        );
      },
      scheduler: ({required workoutId, required date}) async => {},
      deleter: (_) async {},
    );

    final plan = await service.preflight([importWorkout()]);
    final results = await service.commit(plan, confirmed: true);

    expect(uploads, 0);
    expect(results.single.status, GarminImportResultStatus.blockedConflict);
  });

  test('removes a new upload when scheduling fails', () async {
    final deleted = <int>[];

    final service = GarminWorkoutImportService(
      calendarLoader: ({required year, required month}) async => [],
      uploader: (payload) async {
        return GarminUploadedWorkout(
          workoutId: 300,
          workoutName: payload['workoutName'] as String,
        );
      },
      scheduler: ({required workoutId, required date}) async {
        throw const GarminMobileException('Simulated schedule failure');
      },
      deleter: (workoutId) async {
        deleted.add(workoutId);
      },
    );

    final plan = await service.preflight([importWorkout()]);
    final results = await service.commit(plan, confirmed: true);

    expect(deleted, [300]);
    expect(results.single.status, GarminImportResultStatus.failed);
    expect(
      results.single.message,
      'Scheduling failed; the uploaded workout was removed.',
    );
  });

  test('never attempts cleanup when upload itself fails', () async {
    var cleanupCalls = 0;

    final service = GarminWorkoutImportService(
      calendarLoader: ({required year, required month}) async => [],
      uploader: (_) async {
        throw const GarminMobileException('Simulated upload failure');
      },
      scheduler: ({required workoutId, required date}) async => {},
      deleter: (_) async {
        cleanupCalls++;
      },
    );

    final plan = await service.preflight([importWorkout()]);
    final results = await service.commit(plan, confirmed: true);

    expect(cleanupCalls, 0);
    expect(results.single.status, GarminImportResultStatus.failed);
    expect(results.single.workoutId, isNull);
    expect(results.single.message, 'Garmin workout upload failed.');
  });
}
