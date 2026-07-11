import '../models/gear.dart';
import '../models/gear_target.dart';
import '../models/metric.dart';
import '../models/modality.dart';
import '../models/target_history.dart';

List<Gear> buildDefaultMatrix() {
  return [
    _buildRunGear(1, '15:00', '1:00', 2, '9:15', '9:30'),
    _buildRunGear(2, '13:00', '1:15', 2, '8:45', '9:00'),
    _buildRunGear(3, '8:00', '1:30', 3, '8:00', '8:15'),
    _buildRunGear(4, '6:00', '2:30', 3, '7:45', '8:00'),
    _buildRunGear(5, '4:00', '2:45', 4, '7:30', '7:45'),
    _buildRunGear(6, '3:30', '3:00', 4, '7:15', '7:30'),
    _buildRunGear(7, '2:30', '3:15', 5, '7:00', '7:15'),
    _buildRunGear(8, '1:30', '3:30', 7, '6:45', '7:00'),
  ];
}

Gear _buildRunGear(
  int number,
  String work,
  String rest,
  int intervals,
  String lowTarget,
  String highTarget,
) {
  return Gear(
    number: number,
    work: work,
    rest: rest,
    intervals: intervals,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: lowTarget,
            highTarget: highTarget,
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  );
}