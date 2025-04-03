class Aerator {
  final String id;
  final String name;
  final double sotrPerHp;

  Aerator({required this.id, required this.name, required this.sotrPerHp});
}

class PondMetrics {
  final double volume;      // Unchanged, no truncation needed
  final double cs;          // Unchanged, direct from JSON
  final double klaT;        // Unchanged, full precision from minute fractions
  final double kla20;       // Unchanged, full precision from calculation
  final double sotr;        // Truncated to 2 decimals
  final double sae;         // Truncated to 2 decimals
  final double costPerKg;   // Truncated to 2 decimals
  final double powerKw;     // Truncated to 2 decimals

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

  // Factory constructor to create from calculator results
  factory PondMetrics.fromCalculatorResults(Map<String, dynamic> results) {
    return PondMetrics(
      volume: results['Pond Volume (m³)'] as double,
      cs: results['Cs (mg/L)'] as double,
      klaT: results['KlaT (h⁻¹)'] as double,
      kla20: results['Kla20 (h⁻¹)'] as double,
      sotr: results['SOTR (kg O₂/h)'] as double,
      sae: results['SAE (kg O₂/kWh)'] as double,
      costPerKg: results['US\$/kg O₂'] as double,
      powerKw: results['Power (kW)'] as double,
    );
  }
}