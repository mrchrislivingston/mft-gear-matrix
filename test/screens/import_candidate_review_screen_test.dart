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
}
