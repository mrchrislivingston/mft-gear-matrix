import '../models/gear.dart';
import '../models/gear_target.dart';
import '../models/metric.dart';
import '../models/modality.dart';
import '../models/target_history.dart';

List<Gear> buildDefaultMatrix() {
  return [
    _buildGear(1, '15:00', '1:00', 2, '9:15', '9:30'),
    _buildGear(2, '13:00', '1:15', 2, '8:45', '9:00'),
    _buildGear(3, '8:00', '1:30', 3, '8:00', '8:15'),
    _buildGear(4, '6:00', '2:30', 3, '7:45', '8:00'),
    _buildGear(5, '4:00', '2:45', 4, '7:30', '7:45'),
    _buildGear(6, '3:30', '3:00', 4, '7:15', '7:30'),
    _buildGear(7, '2:30', '3:15', 5, '7:00', '7:15'),
    _buildGear(8, '1:30', '3:30', 7, '6:45', '7:00'),
  ];
}

Gear _buildGear(
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
      const GearTarget(
        modality: Modality.row,
        metric: Metric.minPer500m,
      ),
      const GearTarget(
        modality: Modality.ski,
        metric: Metric.minPer500m,
      ),
      const GearTarget(
        modality: Modality.bikeErg,
        metric: Metric.minPer1000m,
      ),
      const GearTarget(
        modality: Modality.echo,
        metric: Metric.rpm,
      ),
    ],
  );
}