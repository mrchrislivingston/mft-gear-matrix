enum TrainingStimulus {
  belowThreshold,
  aerobic,
  anaerobic,
  power,
}

extension TrainingStimulusExtension on TrainingStimulus {
  String get displayName {
    switch (this) {
      case TrainingStimulus.belowThreshold:
        return 'Below Threshold';
      case TrainingStimulus.aerobic:
        return 'Aerobic Stimulus';
      case TrainingStimulus.anaerobic:
        return 'Anaerobic Stimulus';
      case TrainingStimulus.power:
        return 'Power Output';
    }
  }
}