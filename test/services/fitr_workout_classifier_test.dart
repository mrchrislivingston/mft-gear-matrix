import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/fitr_mobile_client.dart';
import 'package:mft_gear_matrix/services/fitr_workout_classifier.dart';

Map<String, dynamic> section(String title, String description) {
  return {'title': title, 'description': description};
}

({int candidates, int skipped}) classifyWeek(
  List<Map<String, dynamic>> sections,
) {
  final results = sections
      .map(classifyFitrSection)
      .whereType<FitrClassification>()
      .toList();

  return (
    candidates: results
        .where((result) => result['status'] == 'CANDIDATE')
        .length,
    skipped: results.where((result) => result['status'] == 'SKIP').length,
  );
}

void main() {
  test('classifies ordinary Gear work', () {
    final result = classifyFitrSection(
      section('Conditioning 3', '''
AMRAP 8:00 x 3
Run for meters @ 3rd Gear
Rest 2:00
'''),
    );

    expect(result!['status'], 'CANDIDATE');
    expect(result['type'], 'GEAR');
    expect(result['prescription'], 'G3');
    expect(result['modality'], 'Run');
    expect(result['rounds'], 3);
    expect(result['work_seconds'], 480);
    expect(result['rest_seconds'], 120);
  });

  test('classifies Power work and calculates recovery', () {
    final result = classifyFitrSection(
      section('Conditioning 3', '''
Every 2:00 for 5 Rounds
Max Calorie Row in :20 @ P1
'''),
    );

    expect(result!['status'], 'CANDIDATE');
    expect(result['type'], 'POWER');
    expect(result['prescription'], 'P1');
    expect(result['modality'], 'Row');
    expect(result['rounds'], 5);
    expect(result['work_seconds'], 20);
    expect(result['recovery_seconds'], 100);
  });

  test('rejects mixed Power prescriptions', () {
    final result = classifyFitrSection(
      section('Conditioning 3', '''
P3 Row
P2 Row
P1 Row
'''),
    );

    expect(result!['status'], 'SKIP');
    expect(result['reason'], 'Mixed Power prescriptions');
  });

  test('classifies Zone 2 and uses minimum duration from range', () {
    final result = classifyFitrSection(
      section('Zone 2 - C2 Bike', '''
15:00 Zone 2 Warm Up
45:00-90:00 C2 Bike @ Zone 2
15:00 Zone 2 Cool Down
'''),
    );

    expect(result!['status'], 'CANDIDATE');
    expect(result['type'], 'Z2');
    expect(result['modality'], 'C2 Bike');
    expect(result['warmup_seconds'], 900);
    expect(result['work_seconds'], 2700);
    expect(result['cooldown_seconds'], 900);
  });

  test('classifies same-modality G7 to G8 Run workout', () {
    final result = classifyFitrSection(
      section('Conditioning 3 (Bitch Work)', '''
Build Run - 7th / 8th Gear

AMRAP 2:30 x 3
Run for Meters @ 7th Gear
Rest 3:15

Rest 3:30 after round 3, Then

AMRAP 2:00 x 2
Run for Meters @ 8th Gear
Rest 3:30
'''),
    );

    expect(result!['status'], 'CANDIDATE');
    expect(result['type'], 'MIXED_GEAR');
    expect(result['prescription'], 'G7-G8');
    expect(result['modality'], 'Run');
    expect(result['rounds'], 5);

    final steps = result['steps']! as List<Map<String, Object?>>;
    expect(steps, [
      {'kind': 'work', 'prescription': 'G7', 'modality': 'Run', 'seconds': 150},
      {'kind': 'recovery', 'seconds': 195},
      {'kind': 'work', 'prescription': 'G7', 'modality': 'Run', 'seconds': 150},
      {'kind': 'recovery', 'seconds': 195},
      {'kind': 'work', 'prescription': 'G7', 'modality': 'Run', 'seconds': 150},
      {'kind': 'recovery', 'seconds': 210},
      {'kind': 'work', 'prescription': 'G8', 'modality': 'Run', 'seconds': 120},
      {'kind': 'recovery', 'seconds': 210},
      {'kind': 'work', 'prescription': 'G8', 'modality': 'Run', 'seconds': 120},
    ]);
  });

  test('classifies reviewed mixed Ski and C2 Bike Gear work', () {
    final result = classifyFitrSection(
      section('Conditioning 3', '''
AMRAP 3:00
Ski for Meters @ 4th Gear
Rest 1:00

AMRAP 3:00
C2 Bike for Meters @ 4th Gear
Rest 1:00

Then 2 Rounds

AMRAP 1:00
Ski for Meters @ 4th Gear
Directly into
AMRAP 1:00
C2 Bike for Meters @ 4th Gear
Rest 1:00
'''),
    );

    expect(result!['status'], 'CANDIDATE');
    expect(result['type'], 'MIXED_GEAR');
    expect(result['prescription'], 'G4');
    expect(result['modality'], 'Ski + C2 Bike');
    expect(result['rounds'], 4);

    final steps = result['steps']! as List<Map<String, Object?>>;
    expect(steps, hasLength(9));
    expect(steps.first['modality'], 'Ski');
    expect(steps[2]['modality'], 'C2 Bike');
  });

  test('matches known 2026-09-07 reference-week totals', () {
    final totals = classifyWeek([
      section('Conditioning 3', '''
Zone 2 - Row
15:00 Zone 2 Warm Up
45:00-90:00 Row @ Zone 2
15:00 Zone 2 Cool Down
'''),
      section('Conditioning 3 (Bitch Work)', '''
Every 2:00 for 5 Rounds
Max Calorie Row in :20 @ P1
'''),
      section('Conditioning 3 (Bitch Work)', '''
AMRAP 8:00 x 3
Run for Meters @ 3rd Gear
Rest 2:00
'''),
      section('Zone 1 / Zone 2', '''
Zone 2 - C2 Bike
15:00 Zone 2 Warm Up
45:00-90:00 C2 Bike @ Zone 2
15:00 Zone 2 Cool Down
'''),
      section('Conditioning 3 (Bitchwork)', '''
AMRAP 6:00 x 4
Echo Bike for Calories @ 1st Gear
Rest 2:00
'''),
      section('Conditioning 3 (Bitch Work)', '''
AMRAP 3:00
Ski for Meters @ 4th Gear
Rest 1:00
AMRAP 3:00
C2 Bike for Meters @ 4th Gear
Rest 1:00
Then 2 Rounds
AMRAP 1:00
Ski for Meters @ 4th Gear
Directly into
AMRAP 1:00
C2 Bike for Meters @ 4th Gear
Rest 1:00
'''),
      section('Zone 1 / Zone 2', '''
Zone 2 - C2 Bike
15:00 Zone 2 Warm Up
45:00-90:00 C2 Bike @ Zone 2
15:00 Zone 2 Cool Down
'''),
    ]);

    expect(totals.candidates, 7);
    expect(totals.skipped, 0);
  });

  test('matches known 2026-09-14 reference-week totals', () {
    final totals = classifyWeek([
      section('Conditioning 3', '''
Zone 2 - Row
15:00 Zone 2 Warm Up
45:00-90:00 Row @ Zone 2
15:00 Zone 2 Cool Down
'''),
      section('Conditioning 3 (Bitch Work)', '''
Every 2:00 for 3 Rounds
Row in :20 @ P3
Row in :30 @ P2
Row in :40 @ P1
'''),
      section('Conditioning 3 (Bitch Work)', '''
AMRAP 6:00 x 4
C2 Bike for Meters @ 1st Gear
Rest 2:00
'''),
    ]);

    expect(totals.candidates, 2);
    expect(totals.skipped, 1);
  });

  test('classifies fetched week and ignores duplicate MATT sections', () {
    final snapshot = FitrWeekSnapshot(
      monday: DateTime(2026, 9, 14),
      sunday: DateTime(2026, 9, 20),
      days: [
        FitrWeekDay(
          date: '2026-09-14',
          scheduleId: 'schedule-one',
          planTitle: 'Misfit Comp Masters',
          calendarDay: const {},
          detail: {
            'day': {
              'sections': [
                {'title': 'Instructions', 'description': 'General notes only'},
                {
                  'title': 'M.A.T.T. Row Test',
                  'description': 'AMRAP 40 Minutes',
                },
                {'title': 'See M.A.T.T. Row Test', 'description': ''},
                {
                  'title': 'Conditioning 3',
                  'description': '''
AMRAP 6:00 x 4
C2 Bike for Meters @ 1st Gear
Rest 2:00
''',
                },
                {
                  'title': 'Conditioning 4',
                  'description': '''
Every 2:00 for 3 Rounds
Row in :20 @ P3
Row in :30 @ P2
Row in :40 @ P1
''',
                },
              ],
            },
          },
        ),
      ],
    );

    final result = classifyFitrWeekSnapshot(snapshot);

    expect(result.candidates, hasLength(2));
    expect(result.skipped, hasLength(1));
    expect(
      result.candidates.map((candidate) => candidate.type),
      containsAll(['MATT', 'GEAR']),
    );
    expect(
      result.candidates.map((candidate) => candidate.id).toSet(),
      hasLength(2),
    );
    expect(result.skipped.single.reason, 'Mixed Power prescriptions');
  });
}
