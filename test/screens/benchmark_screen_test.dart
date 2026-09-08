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
            return {
              'power_output_echo_bike_test': 2,
              'power_output_row_test': 1,
            };
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Power Output'), findsOneWidget);
    expect(find.text('Power Output Echo Bike Test'), findsOneWidget);
    expect(find.text('For Time • 2 attempts'), findsOneWidget);
    expect(find.text('Power Output Row Test'), findsOneWidget);
    expect(find.text('For Time • 1 attempt'), findsOneWidget);
  });
}
