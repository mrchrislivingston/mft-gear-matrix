import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/garmin_import_review_screen.dart';
import 'package:mft_gear_matrix/services/garmin_workout_import_service.dart';

GarminImportWorkout workout() {
  return GarminImportWorkout(
    candidateId: 'candidate-1',
    date: '2026-09-16',
    payload: {
      'workoutName': 'G1 C2 Bike - 2026-09-16',
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

void main() {
  testWidgets('disables writes when every workout is a duplicate', (
    tester,
  ) async {
    var commits = 0;

    final plan = GarminImportPlan([
      GarminImportPlanItem(
        workout: workout(),
        disposition: GarminImportDisposition.exactDuplicate,
        existingWorkouts: const [],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: GarminImportReviewScreen(
          plan: plan,
          committer: (_) async {
            commits++;
            return [];
          },
        ),
      ),
    );

    expect(
      find.text('0 ready • 1 already scheduled • 0 conflicts'),
      findsOneWidget,
    );
    expect(find.textContaining('Garmin will not be changed'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('garminConfirmImportButton')),
    );

    expect(button.onPressed, isNull);
    expect(commits, 0);
  });

  testWidgets('requires acknowledgement before committing ready work', (
    tester,
  ) async {
    var commits = 0;

    final plan = GarminImportPlan([
      GarminImportPlanItem(
        workout: workout(),
        disposition: GarminImportDisposition.ready,
        existingWorkouts: const [],
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: GarminImportReviewScreen(
          plan: plan,
          committer: (confirmedPlan) async {
            commits++;
            expect(confirmedPlan, same(plan));

            return [
              GarminImportResult(
                workout: workout(),
                status: GarminImportResultStatus.scheduled,
                workoutId: 300,
                message: 'Uploaded and scheduled on Garmin.',
              ),
            ];
          },
        ),
      ),
    );

    FilledButton button() => tester.widget<FilledButton>(
      find.byKey(const Key('garminConfirmImportButton')),
    );

    expect(button().onPressed, isNull);

    await tester.tap(find.byKey(const Key('garminImportAcknowledgement')));
    await tester.pump();

    expect(button().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('garminConfirmImportButton')));
    await tester.pumpAndSettle();

    expect(commits, 1);
    expect(find.text('Import results'), findsOneWidget);
    expect(find.textContaining('Uploaded and scheduled'), findsOneWidget);
  });
}
