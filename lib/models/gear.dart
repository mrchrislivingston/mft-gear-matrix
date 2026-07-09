import 'gear_target.dart';
import 'metric.dart';
import 'modality.dart';
import 'target_history.dart';

class Gear {
  final int number;
  final String work;
  final String rest;
  final int intervals;
  final List<GearTarget> targets;

  const Gear({
    required this.number,
    required this.work,
    required this.rest,
    required this.intervals,
    this.targets = const [],
  });

  GearTarget? findTarget({
    required Modality modality,
    required Metric metric,
  }) {
    for (final target in targets) {
      if (target.modality == modality && target.metric == metric) {
        return target;
      }
    }

    return null;
  }

  TargetHistory? currentTarget({
    required Modality modality,
    required Metric metric,
  }) {
    return findTarget(
      modality: modality,
      metric: metric,
    )?.currentTarget;
  }

  GearTarget? get runPaceTarget {
    return findTarget(
      modality: Modality.run,
      metric: Metric.minPerMile,
    );
  }

  String get targetPaceDisplay {
    final target = runPaceTarget;

    if (target == null) {
      return 'No target set';
    }

    return target.displayTarget;
  }
}