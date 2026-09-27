import '../models/gear_target.dart';
import '../models/metric.dart';
import '../models/modality.dart';
import '../models/target_history.dart';

/// Chris's agreed targets, 2026-09-27. G3 is estimated; watts are provisional
/// interval averages from the Sep 20 G7/G8 and Sep 26 G2 workouts.
const assaultRunnerBenchmarks = <String, (String, String, String, String)>{
  'G2': ('8:05', '8:20', '890', '915'),
  'G3': ('7:45', '8:00', '925', '950'),
  'G7': ('6:05', '6:20', '1130', '1175'),
  'G8': ('5:45', '6:00', '1250', '1290'),
};

List<GearTarget> assaultRunnerTargets(String prescriptionId) {
  final values = assaultRunnerBenchmarks[prescriptionId];
  if (values == null) return const [];
  return [
    for (final entry in [
      (Metric.minPerMile, values.$1, values.$2),
      (Metric.watts, values.$3, values.$4),
    ])
      GearTarget(
        modality: Modality.assaultRunner,
        metric: entry.$1,
        history: [TargetHistory(
          lowTarget: entry.$2,
          highTarget: entry.$3,
          effectiveDate: DateTime(2026, 9, 27),
        )],
      ),
  ];
}
