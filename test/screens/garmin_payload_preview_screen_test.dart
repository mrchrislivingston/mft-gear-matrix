import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/garmin_payload_preview_screen.dart';
import 'package:mft_gear_matrix/services/fitr_workout_classifier.dart';

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

  testWidgets('provides an explicit keyboard-dismiss control', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GarminPayloadPreviewScreen(candidates: [zone2Candidate()]),
      ),
    );

    await tester.tap(find.byKey(const Key('garminPayloadAgeField')));
    await tester.pump();

    expect(find.byKey(const Key('garminHideKeyboardButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('garminHideKeyboardButton')));
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.hasFocus ?? false, isFalse);
  });
}
