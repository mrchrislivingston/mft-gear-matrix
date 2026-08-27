import '../models/gear.dart';
import '../models/gear_target.dart';
import '../models/metric.dart';
import '../models/modality.dart';
import '../models/target_history.dart';
import '../models/training_stimulus.dart';

/// Complete list of workout prescriptions.
///
/// Order:
/// Z1–Z2
/// G1–G8
/// P4–P1
List<Prescription> buildDefaultPrescriptions() {
  return [
    _buildZonePrescription(id: 'Z1', name: 'Zone 1'),
    _buildZonePrescription(id: 'Z2', name: 'Zone 2'),

    _buildGear(1, '15:00', '1:00', 2, '9:15', '9:30'),
    _buildGear(2, '8:00', '1:15', 3, '8:45', '9:00'),
    _buildGear(3, '6:00', '1:30', 4, '8:00', '8:15'),
    _buildGear(4, '4:00', '2:00', 5, '7:45', '8:00'),
    _buildGear(5, '3:30', '2:30', 5, '7:30', '7:45'),
    _buildGear(6, '3:00', '3:00', 5, '7:15', '7:30'),
    _buildGear(7, '2:30', '3:15', 5, '7:00', '7:15'),
    _buildGear(8, '2:00', '3:30', 5, '6:45', '7:00'),

    _buildPowerPrescription(
      id: 'P4',
      name: 'Power 4',
      continuousEvery: '3:00',
      continuousRounds: 3,
      continuousAmrap: ':45',
      skiRowEvery: '4:00',
      skiRowRounds: 3,
      skiRowAmrap: '1:15',
    ),
    _buildPowerPrescription(
      id: 'P3',
      name: 'Power 3',
      continuousEvery: '3:00',
      continuousRounds: 3,
      continuousAmrap: ':30-:35',
      skiRowEvery: '4:00',
      skiRowRounds: 3,
      skiRowAmrap: '1:00',
    ),
    _buildPowerPrescription(
      id: 'P2',
      name: 'Power 2',
      continuousEvery: '3:00',
      continuousRounds: 4,
      continuousAmrap: ':20-:25',
      skiRowEvery: '4:00',
      skiRowRounds: 4,
      skiRowAmrap: ':45',
    ),
    _buildPowerPrescription(
      id: 'P1',
      name: 'Power 1',
      continuousEvery: '3:00',
      continuousRounds: 5,
      continuousAmrap: ':10-:20',
      skiRowEvery: '3:00',
      skiRowRounds: 5,
      skiRowAmrap: ':30',
    ),
  ];
}

/// Temporary compatibility function.
///
/// Existing screens can continue requesting a List<Gear> while the rest of
/// the application is gradually migrated to List<Prescription>.
List<Gear> buildDefaultMatrix() {
  return buildDefaultPrescriptions().whereType<Gear>().toList();
}

Prescription _buildZonePrescription({
  required String id,
  required String name,
}) {
  return Prescription(
    id: id,
    name: name,
    stimulus: TrainingStimulus.belowThreshold,
    durationRange: '30:00–90:00',
    targets: _emptyTargets(),
  );
}

Prescription _buildPowerPrescription({
  required String id,
  required String name,
  required String continuousEvery,
  required int continuousRounds,
  required String continuousAmrap,
  required String skiRowEvery,
  required int skiRowRounds,
  required String skiRowAmrap,
}) {
  return Prescription(
    id: id,
    name: name,
    stimulus: TrainingStimulus.power,
    protocols: {
      Modality.run: PrescriptionProtocol(
        every: continuousEvery,
        rounds: continuousRounds,
        amrap: continuousAmrap,
      ),
      Modality.bikeErg: PrescriptionProtocol(
        every: continuousEvery,
        rounds: continuousRounds,
        amrap: continuousAmrap,
      ),
      Modality.echo: PrescriptionProtocol(
        every: continuousEvery,
        rounds: continuousRounds,
        amrap: continuousAmrap,
      ),
      Modality.row: PrescriptionProtocol(
        every: skiRowEvery,
        rounds: skiRowRounds,
        amrap: skiRowAmrap,
      ),
      Modality.ski: PrescriptionProtocol(
        every: skiRowEvery,
        rounds: skiRowRounds,
        amrap: skiRowAmrap,
      ),
    },
    targets: _emptyTargets(),
  );
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
      const GearTarget(modality: Modality.row, metric: Metric.minPer500m),
      const GearTarget(modality: Modality.ski, metric: Metric.minPer500m),
      const GearTarget(modality: Modality.bikeErg, metric: Metric.minPer1000m),
      const GearTarget(modality: Modality.echo, metric: Metric.rpm),
    ],
  );
}

List<GearTarget> _emptyTargets() {
  return const [
    GearTarget(modality: Modality.run, metric: Metric.minPerMile),
    GearTarget(modality: Modality.row, metric: Metric.minPer500m),
    GearTarget(modality: Modality.ski, metric: Metric.minPer500m),
    GearTarget(modality: Modality.bikeErg, metric: Metric.minPer1000m),
    GearTarget(modality: Modality.echo, metric: Metric.rpm),
  ];
}
