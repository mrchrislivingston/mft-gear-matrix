import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/garmin_calendar_service.dart';

void main() {
  late Directory temporaryDirectory;
  late File pythonFile;
  late File bridgeFile;
  late File credentialsFile;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'garmin_calendar_service_test_',
    );
    pythonFile = File('${temporaryDirectory.path}/python')
      ..writeAsStringSync('');
    bridgeFile = File('${temporaryDirectory.path}/bridge.py')
      ..writeAsStringSync('');
    credentialsFile = File('${temporaryDirectory.path}/credentials')
      ..writeAsStringSync('');
  });

  tearDown(() {
    temporaryDirectory.deleteSync(recursive: true);
  });

  test('parses a preview returned by the helper', () async {
    late List<String> capturedArguments;

    final service = GarminCalendarService(
      pythonExecutable: pythonFile.path,
      bridgePath: bridgeFile.path,
      credentialsPath: credentialsFile.path,
      processRunner: (executable, arguments) async {
        expect(executable, pythonFile.path);
        capturedArguments = arguments;

        return ProcessResult(
          1,
          0,
          jsonEncode({
            'from': '2026-09-07',
            'to': '2026-09-13',
            'candidates': [
              {
                'id': 'candidate-one',
                'date': '2026-09-08',
                'planTitle': 'Phase 1 Week 2',
                'sourceTitle': 'Conditioning 3',
                'type': 'POWER',
                'prescription': 'P1',
                'modality': 'Row',
                'workoutName': 'P1 Row - 2026-09-08',
              },
            ],
            'skipped': [
              {
                'id': 'skipped-one',
                'date': '2026-09-12',
                'sourceTitle': 'Conditioning 3',
                'reason': 'Unsupported',
              },
            ],
          }),
          '',
        );
      },
    );

    final preview = await service.preview(
      monday: DateTime(2026, 9, 7),
      age: 50,
      runPaceTargets: const {
        'G3': GarminRunPaceTarget(low: '8:30', high: '8:45'),
      },
    );

    expect(preview.candidates, hasLength(1));
    expect(preview.candidates.single.prescription, 'P1');
    expect(preview.skipped, hasLength(1));
    expect(capturedArguments, [
      bridgeFile.path,
      'preview',
      '--monday',
      '2026-09-07',
      '--age',
      '50',
      '--credentials-file',
      credentialsFile.path,
      '--run-pace-target',
      'G3=8:30,8:45',
    ]);
  });

  test('rejects commit with no selected workouts', () async {
    final service = GarminCalendarService(
      pythonExecutable: pythonFile.path,
      bridgePath: bridgeFile.path,
      credentialsPath: credentialsFile.path,
      processRunner: (_, _) {
        fail('The helper must not run.');
      },
    );

    expect(
      () => service.commit(
        monday: DateTime(2026, 9, 7),
        age: 50,
        selectedIds: const {},
      ),
      throwsA(
        isA<GarminCalendarException>().having(
          (error) => error.message,
          'message',
          contains('Select at least one'),
        ),
      ),
    );
  });

  test('passes only selected IDs to commit', () async {
    late List<String> capturedArguments;

    final service = GarminCalendarService(
      pythonExecutable: pythonFile.path,
      bridgePath: bridgeFile.path,
      credentialsPath: credentialsFile.path,
      processRunner: (_, arguments) async {
        capturedArguments = arguments;

        return ProcessResult(
          1,
          0,
          jsonEncode({
            'results': [
              {
                'id': 'candidate-two',
                'date': '2026-09-09',
                'workoutName': 'G3 Run - 2026-09-09',
                'workoutId': 123,
                'created': true,
                'scheduled': true,
              },
            ],
            'summary': {
              'created': 1,
              'scheduled': 1,
              'alreadyExisting': 0,
              'alreadyScheduled': 0,
            },
          }),
          '',
        );
      },
    );

    final result = await service.commit(
      monday: DateTime(2026, 9, 7),
      age: 50,
      selectedIds: const {'candidate-two'},
    );

    expect(result.results, hasLength(1));
    expect(result.created, 1);
    expect(result.scheduled, 1);
    expect(capturedArguments, contains('commit'));
    expect(capturedArguments, contains('--selected-id'));
    expect(capturedArguments, contains('candidate-two'));
    expect(capturedArguments, isNot(contains('candidate-one')));
  });

  test('reports a helper process failure', () async {
    final service = GarminCalendarService(
      pythonExecutable: pythonFile.path,
      bridgePath: bridgeFile.path,
      credentialsPath: credentialsFile.path,
      processRunner: (_, _) async {
        return ProcessResult(1, 1, '', 'FITR authentication failed');
      },
    );

    expect(
      () => service.preview(monday: DateTime(2026, 9, 7), age: 50),
      throwsA(
        isA<GarminCalendarException>().having(
          (error) => error.message,
          'message',
          contains('FITR authentication failed'),
        ),
      ),
    );
  });
}
