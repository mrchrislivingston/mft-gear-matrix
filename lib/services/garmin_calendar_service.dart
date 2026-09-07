import 'dart:convert';
import 'dart:io';

typedef GarminProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class GarminCalendarException implements Exception {
  final String message;

  const GarminCalendarException(this.message);

  @override
  String toString() => message;
}

class GarminRunPaceTarget {
  final String low;
  final String high;

  const GarminRunPaceTarget({required this.low, required this.high});
}

class GarminCalendarCandidate {
  final String id;
  final String date;
  final String planTitle;
  final String sourceTitle;
  final String type;
  final String prescription;
  final String modality;
  final String workoutName;
  final Map<String, dynamic> classification;

  const GarminCalendarCandidate({
    required this.id,
    required this.date,
    required this.planTitle,
    required this.sourceTitle,
    required this.type,
    required this.prescription,
    required this.modality,
    required this.workoutName,
    this.classification = const {},
  });

  factory GarminCalendarCandidate.fromJson(Map<String, dynamic> json) {
    return GarminCalendarCandidate(
      id: json['id'] as String,
      date: json['date'] as String,
      planTitle: json['planTitle'] as String? ?? '',
      sourceTitle: json['sourceTitle'] as String? ?? '',
      type: json['type'] as String,
      prescription: json['prescription'] as String? ?? '',
      modality: json['modality'] as String? ?? '',
      workoutName: json['workoutName'] as String,
      classification:
          json['classification'] as Map<String, dynamic>? ?? const {},
    );
  }
}

class GarminCalendarSkipped {
  final String id;
  final String date;
  final String sourceTitle;
  final String reason;

  const GarminCalendarSkipped({
    required this.id,
    required this.date,
    required this.sourceTitle,
    required this.reason,
  });

  factory GarminCalendarSkipped.fromJson(Map<String, dynamic> json) {
    return GarminCalendarSkipped(
      id: json['id'] as String,
      date: json['date'] as String,
      sourceTitle: json['sourceTitle'] as String? ?? '',
      reason: json['reason'] as String,
    );
  }
}

class GarminCalendarPreview {
  final String from;
  final String to;
  final List<GarminCalendarCandidate> candidates;
  final List<GarminCalendarSkipped> skipped;

  const GarminCalendarPreview({
    required this.from,
    required this.to,
    required this.candidates,
    required this.skipped,
  });

  factory GarminCalendarPreview.fromJson(Map<String, dynamic> json) {
    final candidateRows = json['candidates'] as List<dynamic>? ?? const [];
    final skippedRows = json['skipped'] as List<dynamic>? ?? const [];

    return GarminCalendarPreview(
      from: json['from'] as String,
      to: json['to'] as String,
      candidates: candidateRows
          .map(
            (row) =>
                GarminCalendarCandidate.fromJson(row as Map<String, dynamic>),
          )
          .toList(growable: false),
      skipped: skippedRows
          .map(
            (row) =>
                GarminCalendarSkipped.fromJson(row as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

class GarminCalendarCommitItem {
  final String id;
  final String date;
  final String workoutName;
  final int workoutId;
  final bool created;
  final bool scheduled;

  const GarminCalendarCommitItem({
    required this.id,
    required this.date,
    required this.workoutName,
    required this.workoutId,
    required this.created,
    required this.scheduled,
  });

  factory GarminCalendarCommitItem.fromJson(Map<String, dynamic> json) {
    return GarminCalendarCommitItem(
      id: json['id'] as String,
      date: json['date'] as String,
      workoutName: json['workoutName'] as String,
      workoutId: json['workoutId'] as int,
      created: json['created'] as bool,
      scheduled: json['scheduled'] as bool,
    );
  }
}

class GarminCalendarCommitResult {
  final List<GarminCalendarCommitItem> results;
  final int created;
  final int scheduled;
  final int alreadyExisting;
  final int alreadyScheduled;

  const GarminCalendarCommitResult({
    required this.results,
    required this.created,
    required this.scheduled,
    required this.alreadyExisting,
    required this.alreadyScheduled,
  });

  factory GarminCalendarCommitResult.fromJson(Map<String, dynamic> json) {
    final resultRows = json['results'] as List<dynamic>? ?? const [];
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};

    return GarminCalendarCommitResult(
      results: resultRows
          .map(
            (row) =>
                GarminCalendarCommitItem.fromJson(row as Map<String, dynamic>),
          )
          .toList(growable: false),
      created: summary['created'] as int? ?? 0,
      scheduled: summary['scheduled'] as int? ?? 0,
      alreadyExisting: summary['alreadyExisting'] as int? ?? 0,
      alreadyScheduled: summary['alreadyScheduled'] as int? ?? 0,
    );
  }
}

class GarminCalendarService {
  final String pythonExecutable;
  final String bridgePath;
  final String credentialsPath;
  final GarminProcessRunner _processRunner;

  GarminCalendarService({
    required this.pythonExecutable,
    required this.bridgePath,
    required this.credentialsPath,
    GarminProcessRunner? processRunner,
  }) : _processRunner = processRunner ?? Process.run;

  factory GarminCalendarService.local() {
    final home = Platform.environment['HOME'];

    if (home == null || home.isEmpty) {
      throw const GarminCalendarException(
        'Unable to determine the current home directory.',
      );
    }

    return GarminCalendarService(
      pythonExecutable:
          Platform.environment['MFT_GARMIN_PYTHON'] ??
          '$home/Development/garmin-test/bin/python',
      bridgePath:
          Platform.environment['MFT_GARMIN_BRIDGE'] ??
          '${Directory.current.path}/tools/'
              'garmin_calendar/bridge.py',
      credentialsPath:
          Platform.environment['MFT_FITR_CREDENTIALS'] ??
          '$home/Development/garmin-test/'
              'fitr_credentials.txt',
    );
  }

  Future<GarminCalendarPreview> preview({
    required DateTime monday,
    required int age,
    Map<String, GarminRunPaceTarget> runPaceTargets = const {},
  }) async {
    final json = await _run([
      'preview',
      '--monday',
      _dateOnly(monday),
      '--age',
      '$age',
      '--credentials-file',
      credentialsPath,
      ..._runPaceTargetArguments(runPaceTargets),
    ]);

    return GarminCalendarPreview.fromJson(json);
  }

  Future<GarminCalendarCommitResult> commit({
    required DateTime monday,
    required int age,
    required Set<String> selectedIds,
    Map<String, GarminRunPaceTarget> runPaceTargets = const {},
  }) async {
    if (selectedIds.isEmpty) {
      throw const GarminCalendarException(
        'Select at least one workout before scheduling.',
      );
    }

    final arguments = [
      'commit',
      '--monday',
      _dateOnly(monday),
      '--age',
      '$age',
      '--credentials-file',
      credentialsPath,
      ..._runPaceTargetArguments(runPaceTargets),
      for (final id in selectedIds) ...['--selected-id', id],
    ];

    final json = await _run(arguments);
    return GarminCalendarCommitResult.fromJson(json);
  }

  List<String> _runPaceTargetArguments(
    Map<String, GarminRunPaceTarget> targets,
  ) {
    final entries = targets.entries.toList()
      ..sort((left, right) {
        return left.key.compareTo(right.key);
      });

    return [
      for (final entry in entries) ...[
        '--run-pace-target',
        '${entry.key}='
            '${entry.value.low},'
            '${entry.value.high}',
      ],
    ];
  }

  Future<Map<String, dynamic>> _run(List<String> bridgeArguments) async {
    final pythonFile = File(pythonExecutable);
    final bridgeFile = File(bridgePath);
    final credentialsFile = File(credentialsPath);

    if (!pythonFile.existsSync()) {
      throw GarminCalendarException(
        'Garmin Python helper not found at '
        '$pythonExecutable',
      );
    }

    if (!bridgeFile.existsSync()) {
      throw GarminCalendarException(
        'Garmin calendar bridge not found at '
        '$bridgePath',
      );
    }

    if (!credentialsFile.existsSync()) {
      throw GarminCalendarException(
        'FITR credentials not found at '
        '$credentialsPath',
      );
    }

    final result = await _processRunner(pythonExecutable, [
      bridgePath,
      ...bridgeArguments,
    ]);

    if (result.exitCode != 0) {
      final error = result.stderr.toString().trim();
      throw GarminCalendarException(
        error.isEmpty
            ? 'Garmin calendar helper failed with '
                  'exit code ${result.exitCode}.'
            : error,
      );
    }

    try {
      final decoded = jsonDecode(result.stdout.toString());

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }

      return decoded;
    } on FormatException catch (error) {
      throw GarminCalendarException(
        'Garmin calendar helper returned invalid JSON: '
        '$error',
      );
    }
  }

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
