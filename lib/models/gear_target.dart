import 'metric.dart';
import 'modality.dart';
import 'target_history.dart';

class GearTarget {
  final Modality modality;
  final Metric metric;
  final List<TargetHistory> history;

  const GearTarget({
    required this.modality,
    required this.metric,
    this.history = const [],
  });

  bool get hasTarget => history.isNotEmpty;

  TargetHistory? get currentTarget {
    if (history.isEmpty) {
      return null;
    }

    return history.last;
  }

  String get displayTarget {
    final target = currentTarget;

    if (target == null) {
      return 'No target';
    }

    return '${target.displayTarget} ${metric.name}';
  }

  GearTarget copyWith({
    List<TargetHistory>? history,
  }) {
    return GearTarget(
      modality: modality,
      metric: metric,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modality': modality.name,
      'metric': metric.name,
      'history': history.map((item) => item.toJson()).toList(),
    };
  }

  factory GearTarget.fromJson(Map<String, dynamic> json) {
    return GearTarget(
      modality: Modality.values.byName(json['modality']),
      metric: Metric.values.byName(json['metric']),
      history: (json['history'] as List)
          .map((item) => TargetHistory.fromJson(item))
          .toList(),
    );
  }
}