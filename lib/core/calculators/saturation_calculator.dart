import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract class SaturationCalculator {
  final String dataPath;
  late Map<String, dynamic> metadata;
  late List<List<double>> matrix;
  late double tempStep;
  late double salStep;
  late String unit;

  SaturationCalculator(this.dataPath) {
    loadData();
  }

  void loadData() {
    try {
      if (kIsWeb || dataPath.isEmpty) {
        // Handle web or empty path case
        throw UnsupportedError('Web platform requires using fromJson constructor');
      } else {
        final file = File(dataPath);
        final data = jsonDecode(file.readAsStringSync());
        _initializeFromJson(data);
      }
    } on FileSystemException {
      throw Exception('Data file not found at $dataPath');
    } on FormatException {
      throw Exception('Invalid JSON format in data file');
    }
  }

  void _initializeFromJson(Map<String, dynamic> data) {
    metadata = data['metadata'];
    matrix = List<List<double>>.from(
      (data['data'] as List).map(
        (row) => List<double>.from((row as List).map((e) => e.toDouble()))
      )
    );
    tempStep = metadata['temperature_range']['step'].toDouble();
    salStep = metadata['salinity_range']['step'].toDouble();
    unit = metadata['unit'];
  }

  double getO2Saturation(double temperature, double salinity) {
    if (temperature < 0 || temperature > 40 || salinity < 0 || salinity > 40) {
      throw ArgumentError('Temperature and salinity must be between 0 and 40');
    }
    final tempIdx = (temperature / tempStep).floor();
    final salIdx = (salinity / salStep).floor();
    return matrix[tempIdx][salIdx];
  }

  double calculateSotr(double temperature, double salinity, double volume,
      [double efficiency = 0.9]);
}

class ShrimpPondCalculator extends SaturationCalculator {
  static const Map<String, double> sotrPerHp = {
    'Generic Paddlewheel': 1.8,
    // 'AquaPaddle Model X V1': 1.9,
    // 'PaddlePro Model Y V2': 1.7,
  };

  ShrimpPondCalculator(super.dataPath);

  factory ShrimpPondCalculator.fromJson(Map<String, dynamic> json) {
    final calculator = ShrimpPondCalculator('');
    calculator._initializeFromJson(json);
    return calculator;
  }

  @override
  double calculateSotr(double temperature, double salinity, double volume,
      [double efficiency = 0.9]) {
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
    final powerKw = hp * 0.746;
    final cs = getO2Saturation(temperature, salinity);
    final cs20 = getO2Saturation(20, salinity);
    final cs20KgM3 = cs20 * 0.001;

    final klaT = 1.1 / ((t70 - t10) / 60);
    final kla20 = klaT * (1.024.pow((20 - temperature).toInt()));

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
    switch (hp) {
      case 2:
        return 40;
      case 3:
        return 70;
      default:
        return hp * 25;
    }
  }

  double getIdealHp(double volume) {
    if (volume <= 40) return 2;
    if (volume <= 70) return 3;
    return (volume / 25).floorToDouble();
  }
}

extension _Power on num {
  double pow(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}