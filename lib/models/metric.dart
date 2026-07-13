enum Metric {
  minPerMile,
  minPer500m,
  minPer1000m,
  rpm,
  watts,
  caloriesPerHour;

  String get displayName {
    switch (this) {
      case Metric.minPerMile:
        return 'Pace';
      case Metric.minPer500m:
        return 'Pace';
      case Metric.minPer1000m:
        return 'Pace';
      case Metric.rpm:
        return 'RPM';
      case Metric.watts:
        return 'Watts';
      case Metric.caloriesPerHour:
        return 'Calories Per Hour';
    }
  }

  String get unitLabel {
    switch (this) {
      case Metric.minPerMile:
        return 'min/mile';
      case Metric.minPer500m:
        return 'min/500m';
      case Metric.minPer1000m:
        return 'min/1000m';
      case Metric.rpm:
        return 'RPM';
      case Metric.watts:
        return 'Watts';
      case Metric.caloriesPerHour:
        return 'Calories Per Hour';
    }
  }

  bool get usesTimeFormat {
    switch (this) {
      case Metric.minPerMile:
      case Metric.minPer500m:
      case Metric.minPer1000m:
        return true;

      case Metric.rpm:
      case Metric.watts:
      case Metric.caloriesPerHour:
        return false;
    }
  }
}