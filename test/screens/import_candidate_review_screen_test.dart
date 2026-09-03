import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/import_candidate_review_screen.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

void main() {
  testWidgets('filters parsed candidates by import status', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const summary = MisfitCandidateSummary(
      candidates: [
        MisfitWorkoutCandidate(
          sourceRow: 10,
          sourceColumn: 4,
          dateHeader: 'W1D1 November 3',
          programDay: 'W1D1',
          workoutType: MisfitWorkoutType.gear,
          prescription: 'G3',
          modality: 'row',
          importStatus: MisfitImportStatus.ready,
          statusReason: 'Single supported workout',
          resultDetail: MisfitResultDetail.intervalResults,
          programmingText: 'Aerobic Row - 3rd Gear',
          resultText: '1000/990/980',
        ),
        MisfitWorkoutCandidate(
          sourceRow: 20,
          sourceColumn: 6,
          dateHeader: 'W2D1 November 10',
          programDay: 'W2D1',
          workoutType: MisfitWorkoutType.zone,
          prescription: 'Z2',
          modality: 'run',
          importStatus: MisfitImportStatus.skip,
          statusReason: 'No result recorded',
          resultDetail: MisfitResultDetail.none,
          programmingText: 'Zone 2 Run',
          resultText: '',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: ImportCandidateReviewScreen(summary: summary)),
    );

    expect(find.text('G3 • row'), findsOneWidget);
    expect(find.text('Z2 • run'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Skipped (1)'));
    await tester.pumpAndSettle();

    expect(find.text('G3 • row'), findsNothing);
    expect(find.text('Z2 • run'), findsOneWidget);
  });

  testWidgets('selects parsed workouts and disables failed workouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const summary = MisfitCandidateSummary(
      candidates: [
        MisfitWorkoutCandidate(
          sourceRow: 10,
          sourceColumn: 4,
          dateHeader: 'W1D1 November 3',
          programDay: 'W1D1',
          workoutType: MisfitWorkoutType.zone,
          prescription: 'Z2',
          modality: 'row',
          importStatus: MisfitImportStatus.ready,
          statusReason: 'Single supported workout',
          resultDetail: MisfitResultDetail.resultTextOnly,
          programmingText: 'Zone 2 - Row\n45:00 Row @ Zone 2',
          resultText: 'Just rowed for 50 min.',
        ),
        MisfitWorkoutCandidate(
          sourceRow: 20,
          sourceColumn: 6,
          dateHeader: 'W2D1 November 10',
          programDay: 'W2D1',
          workoutType: MisfitWorkoutType.zone,
          prescription: 'Z2',
          modality: 'echo',
          importStatus: MisfitImportStatus.ready,
          statusReason: 'Single supported workout',
          resultDetail: MisfitResultDetail.resultTextOnly,
          programmingText: 'Zone 2 - Echo Bike\n45:00 Echo Bike @ Zone 2',
          resultText: 'Too much drama today.',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: ImportCandidateReviewScreen(summary: summary)),
    );

    expect(find.text('Selected for import: 1'), findsOneWidget);

    final enabledCheckbox = find.byWidgetPredicate(
      (widget) => widget is Checkbox && widget.onChanged != null,
    );
    final disabledCheckbox = find.byWidgetPredicate(
      (widget) => widget is Checkbox && widget.onChanged == null,
    );

    expect(enabledCheckbox, findsOneWidget);
    expect(disabledCheckbox, findsOneWidget);
    expect(tester.widget<Checkbox>(enabledCheckbox).value, isTrue);
    expect(tester.widget<Checkbox>(disabledCheckbox).value, isFalse);

    await tester.tap(enabledCheckbox);
    await tester.pump();

    expect(find.text('Selected for import: 0'), findsOneWidget);
    expect(tester.widget<Checkbox>(enabledCheckbox).value, isFalse);
  });
}
