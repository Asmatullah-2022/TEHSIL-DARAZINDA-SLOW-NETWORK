/// An area flagged, from repeated measurements, as having a high rate of
/// poor connectivity. Deliberately never called a "confirmed" or
/// "permanent" dead zone — it is evidence that warrants investigation,
/// not a verified engineering conclusion.
class ProbableDeadZone {
  const ProbableDeadZone({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.measurementCount,
    required this.poorSignalRatio,
    required this.affectedOperators,
    required this.lastMeasuredAt,
    this.averageSignalDbm,
  });

  final double centerLatitude;
  final double centerLongitude;
  final int measurementCount;
  final double? averageSignalDbm;
  final double poorSignalRatio;
  final List<String> affectedOperators;
  final DateTime lastMeasuredAt;
}
