import 'gear_target.dart';
import 'metric.dart';
import 'modality.dart';
import 'target_history.dart';
import 'training_stimulus.dart';

/// Describes a modality-specific workout protocol.
///
/// Example:
/// Every 5:00 x 3
/// AMRAP :30
class PrescriptionProtocol {
  final String every;
  final int rounds;
  final String amrap;

  const PrescriptionProtocol({
    required this.every,
    required this.rounds,
    required this.amrap,
  });

  String get displayText {
    return 'Every $every × $rounds\nAMRAP $amrap';
  }

  Map<String, dynamic> toJson() {
    return {
      'every': every,
      'rounds': rounds,
      'amrap': amrap,
    };
  }

  factory PrescriptionProtocol.fromJson(Map<String, dynamic> json) {
    return PrescriptionProtocol(
      every: json['every'] as String,
      rounds: json['rounds'] as int,
      amrap: json['amrap'] as String,
    );
  }
}

/// Generic workout prescription.
///
/// This can represent:
/// - G1–G8 interval prescriptions
/// - Z1–Z2 continuous-duration prescriptions
/// - P1–P3 modality-specific power protocols
class Prescription {
  final String id;
  final String name;
  final TrainingStimulus stimulus;

  /// Standard interval structure used by G1–G8.
  ///
  /// These remain available for compatibility with the existing Gear screens.
  final String work;
  final String rest;
  final int intervals;

  /// Continuous-duration range used by Z1 and Z2.
  ///
  /// Example: 30:00–90:00
  final String? durationRange;

  /// Modality-specific protocols used by P1–P3.
  final Map<Modality, PrescriptionProtocol> protocols;

  final List<GearTarget> targets;

  const Prescription({
    required this.id,
    required this.name,
    required this.stimulus,
    this.work = '',
    this.rest = '',
    this.intervals = 1,
    this.durationRange,
    this.protocols = const {},
    this.targets = const [],
  });

  bool get isContinuous {
    return durationRange != null;
  }

  bool get hasModalityProtocols {
    return protocols.isNotEmpty;
  }

  /// Only Gear prescriptions use manually managed targets.
  ///
  /// Zone and Power prescriptions are tracking and analytics only.
  bool get supportsTargets {
    return this is Gear;
  }

  PrescriptionProtocol? protocolForModality(Modality modality) {
    return protocols[modality];
  }

  String prescriptionDisplayForModality(Modality modality) {
    final protocol = protocolForModality(modality);

    if (protocol != null) {
      return protocol.displayText;
    }

    if (durationRange != null) {
      return durationRange!;
    }

    return '$work work / $rest rest × $intervals';
  }

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

  String targetDisplayForModality(Modality modality) {
    final target = targetForModality(modality);

    if (target == null) {
      return 'No target';
    }

    return target.displayTarget;
  }

  Prescription copyWith({
    List<GearTarget>? targets,
    String? durationRange,
    Map<Modality, PrescriptionProtocol>? protocols,
  }) {
    return Prescription(
      id: id,
      name: name,
      stimulus: stimulus,
      work: work,
      rest: rest,
      intervals: intervals,
      durationRange: durationRange ?? this.durationRange,
      protocols: protocols ?? this.protocols,
      targets: targets ?? this.targets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stimulus': stimulus.name,
      'work': work,
      'rest': rest,
      'intervals': intervals,
      'durationRange': durationRange,
      'protocols': protocols.map(
        (modality, protocol) => MapEntry(
          modality.name,
          protocol.toJson(),
        ),
      ),
      'targets': targets.map((target) => target.toJson()).toList(),
    };
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final protocolJson =
        Map<String, dynamic>.from(json['protocols'] as Map? ?? {});

    return Prescription(
      id: json['id'] as String,
      name: json['name'] as String,
      stimulus: TrainingStimulus.values.byName(
        json['stimulus'] as String,
      ),
      work: json['work'] as String? ?? '',
      rest: json['rest'] as String? ?? '',
      intervals: json['intervals'] as int? ?? 1,
      durationRange: json['durationRange'] as String?,
      protocols: protocolJson.map(
        (modalityName, protocol) => MapEntry(
          Modality.values.byName(modalityName),
          PrescriptionProtocol.fromJson(
            Map<String, dynamic>.from(protocol as Map),
          ),
        ),
      ),
      targets: (json['targets'] as List? ?? [])
          .map(
            (item) => GearTarget.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

/// Temporary compatibility class.
///
/// Existing parts of the app can continue using Gear while we gradually
/// migrate them to the generic Prescription model.
class Gear extends Prescription {
  final int number;

  const Gear({
    required this.number,
    required super.work,
    required super.rest,
    required super.intervals,
    super.targets = const [],
  }) : super(
          id: 'G$number',
          name: 'Gear $number',
          stimulus: number <= 3
              ? TrainingStimulus.aerobic
              : TrainingStimulus.anaerobic,
        );

  GearTarget? get runPaceTarget {
    return findTarget(
      modality: Modality.run,
      metric: Metric.minPerMile,
    );
  }

  String get targetPaceDisplay {
    return targetDisplayForModality(Modality.run);
  }

  @override
  Gear copyWith({
    List<GearTarget>? targets,
    String? durationRange,
    Map<Modality, PrescriptionProtocol>? protocols,
  }) {
    return Gear(
      number: number,
      work: work,
      rest: rest,
      intervals: intervals,
      targets: targets ?? this.targets,
    );
  }

  @override
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
      number: json['number'] as int,
      work: json['work'] as String,
      rest: json['rest'] as String,
      intervals: json['intervals'] as int,
      targets: (json['targets'] as List? ?? [])
          .map(
            (item) => GearTarget.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}