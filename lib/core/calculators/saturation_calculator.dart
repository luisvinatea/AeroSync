import 'dart:convert';
import 'dart:math' show pow; // Import pow from dart:math
import 'package:flutter/services.dart' show rootBundle;

abstract class SaturationCalculator {
  final String dataPath;
  late Map<String, dynamic> metadata;
  late List<List<double>> matrix;
  late double tempStep;
  late double salStep;
  late String unit;

  SaturationCalculator(this.dataPath) {
    // Call async loadData in an async context later, not here
  }

  Future<void> loadData() async {
    try {
      final jsonString = await rootBundle.loadString(dataPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      metadata = data['metadata'] as Map<String, dynamic>;
      matrix = (data['data'] as List).map((row) => (row as List).map((e) => e as double).toList()).toList();
      tempStep = metadata['temperature_range']['step'] as double;
      salStep = metadata['salinity_range']['step'] as double;
      unit = metadata['unit'] as String;
    } catch (e) {
      throw Exception('Failed to load or parse data from $dataPath: $e');
    }
  }

  double getO2Saturation(double temperature, double salinity) {
    if (!(0 <= temperature && temperature <= 40 && 0 <= salinity && salinity <= 40)) {
      throw ArgumentError('Temperature and salinity must be between 0 and 40');
    }
    final tempIdx = (temperature / tempStep).floor();
    final salIdx = (salinity / salStep).floor();
    return matrix[tempIdx][salIdx];
  }

  double calculateSotr(double temperature, double salinity, double volume, {double efficiency = 0.9});
}

class ShrimpPondCalculator extends SaturationCalculator {
  static const Map<String, double> sotrPerHp = {
    'Generic Paddlewheel': 1.8,
  };

  ShrimpPondCalculator(String dataPath) : super(dataPath);

  @override
  double calculateSotr(double temperature, double salinity, double volume, {double efficiency = 0.9}) {
    final saturation = getO2Saturation(temperature, salinity);
    final saturationKgM3 = saturation * 0.001;
    return saturationKgM3 * volume * efficiency;
  }

  Map<String, dynamic> calculateMetrics({
    required double temperature,
    required double salinity,
    required double hp,
    required double volume,
    required double t10,
    required double t70,
    required double kwhPrice,
    required String aeratorId,
    double doDeficitFactor = 1.0,
    double waterDepthFactor = 1.0,
    double placementFactor = 1.0,
  }) {
    final powerKw = hp * 0.746; // 1 hp = 0.746 kW
    final cs = getO2Saturation(temperature, salinity);
    final cs20 = getO2Saturation(20, salinity);
    final cs20KgM3 = cs20 * 0.001; // mg/L to kg/m³

    final klaT = 1.1 / ((t70 - t10) / 60); // Convert time difference to hours
    final kla20 = klaT * pow(1.024, 20 - temperature).toDouble(); // Use pow from dart:math

    final sotr = kla20 * cs20KgM3 * volume;
    final sae = powerKw > 0 ? sotr / powerKw : 0;
    final costPerKg = sae > 0 ? kwhPrice / sae : double.infinity;

    return {
      'Pond Volume (m³)': volume,
      'Cs (mg/L)': cs,
      'KlaT (h⁻¹)': klaT,
      'Kla20 (h⁻¹)': kla20,
      'SOTR (kg O₂/h)': sotr,
      'SAE (kg O₂/kWh)': sae,
      'US\$/kg O₂': costPerKg,
      'Power (kW)': powerKw,
    };
  }

  double getIdealVolume(double hp) {
    if (hp == 2) return 40;
    if (hp == 3) return 70;
    return hp * 25;
  }

  int getIdealHp(double volume) {
    if (volume <= 40) return 2;
    if (volume <= 70) return 3;
    return (volume / 25).ceil().clamp(2, double.infinity).toInt();
  }
}