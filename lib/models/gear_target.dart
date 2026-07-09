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

  TargetHistory? get currentTarget {
    if (history.isEmpty) {
      return null;
    }

    return history.last;
  }

  String get displayTarget {
    final target = currentTarget;

    if (target == null) {
      return 'No target set';
    }

    return '${target.displayTarget} ${metric.name}';
  }
}