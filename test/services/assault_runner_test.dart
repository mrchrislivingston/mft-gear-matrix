import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/data/default_matrix.dart';
import 'package:mft_gear_matrix/data/assault_runner_targets.dart';
import 'package:mft_gear_matrix/models/metric.dart';
import 'package:mft_gear_matrix/models/modality.dart';
import 'package:mft_gear_matrix/models/workout_metric.dart';
import 'package:mft_gear_matrix/screens/log_workout_screen.dart';
import 'package:mft_gear_matrix/screens/target_manager_screen.dart';
import 'package:mft_gear_matrix/services/fitr_workout_classifier.dart';
import 'package:mft_gear_matrix/services/garmin_workout_builder.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

void main() {
  final gear = buildDefaultMatrix().firstWhere((g) => g.id == 'G2')
      .copyWith(targets: assaultRunnerTargets('G2').reversed.toList());

  test('pace remains primary even when watts are first in storage', () {
    expect(gear.targetForModality(Modality.assaultRunner)!.metric, Metric.minPerMile);
    expect(gear.findTarget(modality: Modality.assaultRunner, metric: Metric.watts)!.currentTarget!.lowTarget, '890');
    expect(Modality.assaultRunner.workoutMetrics, contains(WorkoutMetric.watts));
    expect(gear.toJson()['targets'], isNotEmpty);
    expect(buildDefaultPrescriptions().firstWhere((p) => p.id == 'P1')
        .protocolForModality(Modality.assaultRunner), isNotNull);
  });

  test('classifies aliases for Gear, Power, Zone and distinguishes outdoor', () {
    for (final alias in ['AssaultRunner', 'Assault Runner', 'Ass Runner']) {
      final result = classifyFitrSection({'title': 'G2', 'description': 'AMRAP 4:30 x 6\n$alias for meters @ G2\nRest :40'});
      expect(result!['modality'], 'AssaultRunner');
      expect(classifyFitrSection({'title': 'P1', 'description': 'Every 3:00 x 5\n$alias for meters in :20 @ P1'})!['modality'], 'AssaultRunner');
      expect(classifyFitrSection({'title': 'Zone 2 - $alias', 'description': '30:00 $alias @ Zone 2'})!['modality'], 'AssaultRunner');
    }
    expect(detectFitrModality('Run\nEquipment Modification\nAssaultRunner'), 'Run');
    expect(detectFitrModality('Run and AssaultRunner'), isNull);
    final parser = MisfitWorkoutParser();
    expect(parser.detectCandidateModalities(programmingText: 'Run @ G2', resultText: 'AssaultRunner 907m'), ['assaultRunner']);
    expect(parser.detectModalities('Assault Bike'), ['echo']);
  });

  test('changing a Run candidate removes outdoor pace and resolves AR target', () {
    final run = FitrWorkoutCandidate(id: 'test', date: '2026-09-26', planTitle: 'Test', sourceTitle: 'G2', classification: {
      'type': 'GEAR', 'prescription': 'G2', 'modality': 'Run',
      'rounds': 6, 'work_seconds': 270, 'rest_seconds': 40,
      'pace_low': '8:45', 'pace_high': '9:00',
    });
    final runner = run.withRunningModality('AssaultRunner');
    expect(runner.classification.containsKey('pace_low'), isFalse);
    const builder = GarminWorkoutBuilder();
    expect(builder.missingGearTargets(runner).single.modality, 'AssaultRunner');
    expect(() => builder.buildCandidate(runner, age: 50), throwsA(isA<GarminWorkoutBuilderException>()));
    final payload = builder.buildCandidate(runner, age: 50, gearTargetResolver: (id, modality) {
      expect(modality, 'AssaultRunner');
      return const GarminGearTarget(metric: 'minPerMile', low: '8:05', high: '8:20');
    });
    expect(payload['sportType']['sportTypeKey'], 'running');
    final steps = payload['workoutSegments'][0]['workoutSteps'] as List;
    expect(steps.first['targetValueOne'], closeTo(1609.344 / 485, 0.0001));
    expect(steps[1]['targetType']['workoutTargetTypeKey'], 'no.target');
  });

  testWidgets('watts editor loads watts rather than pace', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TargetManagerScreen(
      prescription: gear, modality: Modality.assaultRunner, metric: Metric.watts,
    )));
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, '890');
    expect(fields[1].controller!.text, '915');
  });

  testWidgets('AssaultRunner logging uses meters, pace and watts', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LogWorkoutScreen(prescription: gear, modality: Modality.assaultRunner)));
    expect(find.text('Distance (meters)'), findsWidgets);
    expect(find.text('Pace (min/mile)'), findsWidgets);
    expect(find.text('Watts'), findsWidgets);
  });
}
