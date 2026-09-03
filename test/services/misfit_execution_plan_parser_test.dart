import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_execution_plan_parser.dart';

void main() {
  const parser = MisfitExecutionPlanParser();

  test('parses multiplication symbol format', () {
    final plan = parser.extract('BikeErg - 6th Gear\n8×1:45');

    expect(plan, isNotNull);
    expect(plan!.intervalCount, 8);
    expect(plan.workDuration, '1:45');
  });

  test('parses lowercase x format', () {
    final plan = parser.extract('Run - 6th Gear\n4x3:30');

    expect(plan, isNotNull);
    expect(plan!.intervalCount, 4);
    expect(plan.workDuration, '3:30');
  });

  test('parses uppercase x with spaces', () {
    final plan = parser.extract('SkiErg - 5th Gear\n4 X 3:30');

    expect(plan, isNotNull);
    expect(plan!.intervalCount, 4);
    expect(plan.workDuration, '3:30');
  });

  test('parses duration-first format', () {
    final plan = parser.extract(
      'Build Bike\n\n'
      'AMRAP 1:45 x 8\n'
      'C2 Bike for Meters @ 6th Gear\n'
      'Rest 1:45',
    );

    expect(plan, isNotNull);
    expect(plan!.intervalCount, 8);
    expect(plan.workDuration, '1:45');
  });

  test('uses first execution plan in multiline programming', () {
    final plan = parser.extract(
      'BikeErg - 6th Gear\n'
      '8×1:45\n'
      'Maintain pace.\n'
      'Then cooldown 10:00.',
    );

    expect(plan, isNotNull);
    expect(plan!.intervalCount, 8);
    expect(plan.workDuration, '1:45');
  });

  test('parses P3 power rounds', () {
    final plan = parser.extract(
      'Power - Air Bike\n'
      'Every 5:00 for 3 Rounds\n'
      'Max Calorie Air Bike in :25 @ P3\n'
      'Recover in Remaining Time',
    );

    expect(plan, isNotNull);
    expect(plan!.intervalCount, 3);
    expect(plan.workDuration, ':25');
  });

  test('parses P1 power rounds', () {
    final plan = parser.extract(
      'Power - Air Bike\n'
      'Every 3:00 for 5 Rounds\n'
      'Max Calorie Air Bike in :15 @ P1',
    );

    expect(plan, isNotNull);
    expect(plan!.intervalCount, 5);
    expect(plan.workDuration, ':15');
  });

  test('parses P2 power rounds', () {
    final plan = parser.extract(
      'Power - Air Bike\n'
      'Every 4:00 for 4 Rounds\n'
      'Max Calorie Air Bike in :20 @ P2',
    );

    expect(plan, isNotNull);
    expect(plan!.intervalCount, 4);
    expect(plan.workDuration, ':20');
  });

  test('returns null for unstructured programming', () {
    expect(parser.extract('BikeErg - 1st Gear'), isNull);
    expect(parser.extract(null), isNull);
  });
}
