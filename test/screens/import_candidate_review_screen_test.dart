import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/import_candidate_review_screen.dart';
import 'package:mft_gear_matrix/services/misfit_benchmark_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_date_resolver.dart';
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
  testWidgets('allows a parsed review workout to be manually included', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const summary = MisfitCandidateSummary(
      candidates: [
        MisfitWorkoutCandidate(
          sourceRow: 19,
          sourceColumn: 10,
          dateHeader: 'Wed - Feb 4 - W5D3',
          programDay: 'W5D3',
          workoutType: MisfitWorkoutType.gear,
          prescription: 'G7',
          modality: 'echo',
          importStatus: MisfitImportStatus.review,
          statusReason: 'Result may describe a partial workout',
          resultDetail: MisfitResultDetail.intervalResults,
          programmingText:
              'Build Echo - 7th Gear\n'
              'AMRAP 2:30 x 5\n'
              'Echo Bike for Meters @ 7th Gear\n'
              'Rest 3:15',
          resultText:
              'Made it through 3 rounds.\n'
              'RPM/Cals/Watts/KM\n'
              '73/54/434/1.84KM\n'
              '74/56/451/1.86KM\n'
              '74/56/451/1.86KM',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: ImportCandidateReviewScreen(summary: summary)),
    );

    expect(find.text('Selected for import: 0'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Needs review (1)'));
    await tester.pumpAndSettle();

    expect(find.text('G7 • echo'), findsOneWidget);

    await tester.tap(find.text('G7 • echo'));
    await tester.pumpAndSettle();

    expect(find.text('Captured intervals: 3'), findsOneWidget);

    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget);
    expect(tester.widget<Checkbox>(checkbox).onChanged, isNotNull);
    expect(tester.widget<Checkbox>(checkbox).value, isFalse);

    await tester.tap(checkbox);
    await tester.pump();

    expect(find.text('Selected for import: 1'), findsOneWidget);
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
  });

  testWidgets('shows Matrix and benchmark selections in one review', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const matrixSummary = MisfitCandidateSummary(candidates: []);
    const benchmarkSummary = MisfitBenchmarkCandidateSummary(
      candidates: [
        MisfitBenchmarkCandidate(
          sourceRow: 4,
          sourceColumn: 7,
          resultSourceRow: 5,
          dateHeader: 'Tues - W1D2 July 28',
          programDay: 'W1D2',
          date: '2026-07-28',
          dateStatus: MisfitDateStatus.exact,
          benchmarkKey: 'pennies',
          benchmarkName: 'Pennies',
          modality: 'run',
          programmingText: '"Pennies"',
          resultText: '16:56 - Scaled to 185 and 4 RMU.',
          resultStatus: MisfitBenchmarkResultStatus.selected,
          resultReason: 'Single nonempty result row',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ImportCandidateReviewScreen(
          summary: matrixSummary,
          benchmarkSummary: benchmarkSummary,
        ),
      ),
    );

    expect(find.text('Selected for import: 1'), findsOneWidget);
    expect(find.text('Matrix: 0 • Benchmarks: 1'), findsOneWidget);
    expect(find.text('Pennies'), findsOneWidget);

    await tester.tap(find.text('Pennies'));
    await tester.pumpAndSettle();

    expect(find.text('Score: 16:56'), findsOneWidget);
    expect(find.text('Benchmark ID: pennies'), findsOneWidget);
  });
}
