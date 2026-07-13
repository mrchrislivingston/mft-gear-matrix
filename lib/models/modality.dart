import 'metric.dart';

enum Modality {
  run,
  row,
  ski,
  bikeErg,
  echo;

  String get displayName {
    switch (this) {
      case Modality.run:
        return 'Run';
      case Modality.row:
        return 'Row';
      case Modality.ski:
        return 'SkiErg';
      case Modality.bikeErg:
        return 'C2 Bike';
      case Modality.echo:
        return 'Echo Bike';
    }
  }

  Metric get defaultMetric {
    switch (this) {
      case Modality.run:
        return Metric.minPerMile;
      case Modality.row:
        return Metric.minPer500m;
      case Modality.ski:
        return Metric.minPer500m;
      case Modality.bikeErg:
        return Metric.minPer1000m;
      case Modality.echo:
        return Metric.rpm;
    }
  }
}