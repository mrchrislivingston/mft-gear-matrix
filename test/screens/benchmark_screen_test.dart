import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/screens/benchmark_screen.dart';

void main() {
  testWidgets('shows attempt count for each benchmark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: BenchmarkScreen(
          attemptCountsLoader: () async {
            return {'matt_echo_bike': 2, 'matt_row': 1};
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Average Watts • 2 attempts'), findsOneWidget);
    expect(find.text('Average Watts • 1 attempt'), findsOneWidget);
    expect(find.text('Total Reps • 0 attempts'), findsOneWidget);
  });
}
