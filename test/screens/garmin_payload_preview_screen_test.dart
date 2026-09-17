import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/garmin_payload_preview_screen.dart';
import 'package:mft_gear_matrix/services/fitr_workout_classifier.dart';
import 'package:mft_gear_matrix/services/garmin_mobile_client.dart';
import 'package:mft_gear_matrix/services/garmin_workout_builder.dart';

FitrWorkoutCandidate zone2Candidate() {
  return const FitrWorkoutCandidate(
    id: 'schedule:0:Z2',
    date: '2026-09-10',
    planTitle: 'Test Plan',
    sourceTitle: 'Zone 1 / Zone 2',
    classification: {
      'status': 'CANDIDATE',
      'type': 'Z2',
      'prescription': 'Z2',
      'modality': 'C2 Bike',
      'source_title': 'Zone 1 / Zone 2',
      'workout_date': '2026-09-10',
      'work_seconds': 1800,
    },
  );
}

FitrWorkoutCandidate gearCandidate() {
  return const FitrWorkoutCandidate(
    id: 'schedule:0:GEAR',
    date: '2026-09-10',
    planTitle: 'Test Plan',
    sourceTitle: 'Conditioning',
    classification: {
      'status': 'CANDIDATE',
      'type': 'GEAR',
      'prescription': 'G1',
      'modality': 'C2 Bike',
      'source_title': 'Conditioning',
      'workout_date': '2026-09-10',
      'rounds': 2,
      'work_seconds': 900,
      'rest_seconds': 60,
    },
  );
}

void main() {
  testWidgets('requires athlete age before building payloads', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GarminPayloadPreviewScreen(candidates: [zone2Candidate()]),
      ),
    );

    await tester.tap(find.byKey(const Key('garminBuildPayloadPreviewButton')));
    await tester.pump();

    expect(
      find.text('Enter the athlete’s current age from 1 through 119.'),
      findsOneWidget,
    );
    expect(find.text('Built payloads'), findsNothing);
  });

  testWidgets('builds a readable age-specific preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: GarminPayloadPreviewScreen(candidates: [zone2Candidate()]),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('garminPayloadAgeField')),
      '28',
    );
    await tester.tap(find.byKey(const Key('garminBuildPayloadPreviewButton')));
    await tester.pump();

    expect(find.text('Built payloads'), findsOneWidget);
    expect(find.text('Z2 C2 Bike - 2026-09-10'), findsOneWidget);
    expect(find.text('Z2 • 7 Garmin steps'), findsOneWidget);

    await tester.tap(find.text('Z2 C2 Bike - 2026-09-10'));
    await tester.pumpAndSettle();

    expect(find.text('Cycling'), findsOneWidget);
    expect(find.text('Total 60:00'), findsOneWidget);
    expect(find.text('Step 1 • Warm-up'), findsOneWidget);
    expect(find.text('Duration: 5:00'), findsWidgets);
    expect(find.text('Heart rate: 100–132 bpm'), findsWidgets);
    expect(find.text('Technical JSON'), findsOneWidget);
  });

  testWidgets('opens Target Manager recovery and rebuilds payloads', (
    tester,
  ) async {
    var targetAvailable = false;
    var editedTargets = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: GarminPayloadPreviewScreen(
          candidates: [gearCandidate()],
          gearTargetResolver: (_, _) {
            if (!targetAvailable) {
              return null;
            }

            return const GarminGearTarget(
              metric: 'minPer1000m',
              low: '1:47',
              high: '1:48',
            );
          },
          missingTargetEditor: (requirement) async {
            expect(requirement.prescription, 'G1');
            expect(requirement.modality, 'C2 Bike');
            editedTargets++;
            targetAvailable = true;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('garminPayloadAgeField')),
      '50',
    );
    await tester.tap(find.byKey(const Key('garminBuildPayloadPreviewButton')));
    await tester.pump();

    expect(find.text('Targets required'), findsOneWidget);
    expect(find.text('G1 C2 Bike'), findsOneWidget);
    expect(find.text('Built payloads'), findsNothing);

    await tester.tap(find.byKey(const Key('garminSetTarget-G1:C2 Bike')));
    await tester.pumpAndSettle();

    expect(editedTargets, 1);
    expect(find.text('Targets required'), findsNothing);
    expect(find.text('Built payloads'), findsOneWidget);
  });

  testWidgets('restores the database and retries payload construction', (
    tester,
  ) async {
    var targetAvailable = false;
    var restores = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: GarminPayloadPreviewScreen(
          candidates: [gearCandidate()],
          gearTargetResolver: (_, _) {
            if (!targetAvailable) {
              return null;
            }

            return const GarminGearTarget(
              metric: 'minPer1000m',
              low: '1:47',
              high: '1:48',
            );
          },
          databaseRestoreLauncher: () async {
            restores++;
            targetAvailable = true;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('garminPayloadAgeField')),
      '50',
    );
    await tester.tap(find.byKey(const Key('garminBuildPayloadPreviewButton')));
    await tester.pump();

    expect(find.text('Targets required'), findsOneWidget);

    final restoreButton = find.byKey(const Key('garminRestoreDatabaseButton'));
    await tester.ensureVisible(restoreButton);
    await tester.pumpAndSettle();
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();

    expect(restores, 1);
    expect(find.text('Targets required'), findsNothing);
    expect(find.text('Built payloads'), findsOneWidget);
  });

  testWidgets('provides an explicit keyboard-dismiss control', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GarminPayloadPreviewScreen(candidates: [zone2Candidate()]),
      ),
    );

    await tester.tap(find.byKey(const Key('garminPayloadAgeField')));
    await tester.pump();

    final ageField = tester.widget<EditableText>(find.byType(EditableText));

    expect(ageField.focusNode.hasFocus, isTrue);
    expect(find.byKey(const Key('garminHideKeyboardButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('garminHideKeyboardButton')));
    await tester.pump();

    expect(ageField.focusNode.hasFocus, isFalse);
  });

  testWidgets('shows an exact existing Garmin schedule match', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: GarminPayloadPreviewScreen(
          candidates: [zone2Candidate()],
          calendarLoader: (dates) async {
            expect(dates.single, DateTime(2026, 9, 10));

            return const [
              GarminScheduledWorkout(
                scheduleId: 1770727450,
                workoutId: 1691105243,
                title: 'Z2 C2 Bike - 2026-09-10',
                date: '2026-09-10',
                sportTypeKey: 'cycling',
              ),
            ];
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('garminPayloadAgeField')),
      '50',
    );
    await tester.tap(find.byKey(const Key('garminBuildPayloadPreviewButton')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('garminCheckCalendarButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Already scheduled on Garmin'), findsOneWidget);
    expect(
      find.text(
        'Garmin calendar check completed for 1 workout. '
        'Review each workout status, then continue.',
      ),
      findsOneWidget,
    );
  });
}
