import '../models/gear.dart';
import '../models/gear_target.dart';
import '../models/metric.dart';
import '../models/modality.dart';
import '../models/target_history.dart';

final runGears = [
  Gear(
    number: 1,
    work: '15:00',
    rest: '1:00',
    intervals: 2,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: '9:15',
            highTarget: '9:30',
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  ),
  Gear(
    number: 2,
    work: '13:00',
    rest: '1:15',
    intervals: 2,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: '8:45',
            highTarget: '9:00',
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  ),
  Gear(
    number: 3,
    work: '8:00',
    rest: '1:30',
    intervals: 3,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: '8:00',
            highTarget: '8:15',
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  ),
  Gear(
    number: 4,
    work: '6:00',
    rest: '2:30',
    intervals: 3,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: '7:45',
            highTarget: '8:00',
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  ),
  Gear(
    number: 5,
    work: '4:00',
    rest: '2:45',
    intervals: 4,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: '7:30',
            highTarget: '7:45',
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  ),
  Gear(
    number: 6,
    work: '3:30',
    rest: '3:00',
    intervals: 4,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: '7:15',
            highTarget: '7:30',
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  ),
  Gear(
    number: 7,
    work: '2:30',
    rest: '3:15',
    intervals: 5,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: '7:00',
            highTarget: '7:15',
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  ),
  Gear(
    number: 8,
    work: '1:30',
    rest: '3:30',
    intervals: 7,
    targets: [
      GearTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
        history: [
          TargetHistory(
            lowTarget: '6:45',
            highTarget: '7:00',
            effectiveDate: DateTime.now(),
          ),
        ],
      ),
    ],
  ),
];