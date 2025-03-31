class Aerator {
  final String id;
  final String name;
  final double sotrPerHp;

  Aerator({required this.id, required this.name, required this.sotrPerHp});
}

class PondMetrics {
  final double volume;
  final double cs;
  final double klaT;
  final double kla20;
  final double sotr;
  final double sae;
  final double costPerKg;
  final double powerKw;

  PondMetrics({
    required this.volume,
    required this.cs,
    required this.klaT,
    required this.kla20,
    required this.sotr,
    required this.sae,
    required this.costPerKg,
    required this.powerKw,
  });
}