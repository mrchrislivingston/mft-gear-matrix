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

  GearTarget? targetForModality(Modality modality) {
    for (final target in targets) {
      if (target.modality == modality) {
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

  /// Generic helper for Sprint 6+
  String targetDisplayForModality(Modality modality) {
    final target = targetForModality(modality);

    if (target == null) {
      return 'No target';
    }

    return target.displayTarget;
  }

  //
  // Legacy Run helpers
  // (kept temporarily so existing screens continue to compile)
  //

  GearTarget? get runPaceTarget {
    return findTarget(
      modality: Modality.run,
      metric: Metric.minPerMile,
    );
  }

  String get targetPaceDisplay {
    return targetDisplayForModality(Modality.run);
  }

  Gear copyWith({
    List<GearTarget>? targets,
  }) {
    return Gear(
      number: number,
      work: work,
      rest: rest,
      intervals: intervals,
      targets: targets ?? this.targets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'work': work,
      'rest': rest,
      'intervals': intervals,
      'targets': targets.map((target) => target.toJson()).toList(),
    };
  }

  factory Gear.fromJson(Map<String, dynamic> json) {
    return Gear(
      number: json['number'],
      work: json['work'],
      rest: json['rest'],
      intervals: json['intervals'],
      targets: (json['targets'] as List)
          .map((item) => GearTarget.fromJson(item))
          .toList(),
    );
  }
}