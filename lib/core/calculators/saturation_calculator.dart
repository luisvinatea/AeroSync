import 'dart:convert';
import 'dart:math' show pow;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

abstract class SaturationCalculator {
  final String dataPath;
  late Map<String, dynamic> metadata;
  late List<List<double>> matrix;
  late double tempStep;
  late double salStep;
  late String unit;

  SaturationCalculator(this.dataPath);

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('o2_saturation_data');

      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        _parseData(data);
      } else {
        final jsonString = await rootBundle.loadString(dataPath);
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        _parseData(data);
        await prefs.setString('o2_saturation_data', jsonString);
      }
    } catch (e) {
      throw Exception('Failed to load or parse data from $dataPath: $e');
    }
  }

  void _parseData(Map<String, dynamic> data) {
    metadata = data['metadata'] as Map<String, dynamic>;
    matrix = (data['data'] as List)
        .map((row) => (row as List).map((e) => e as double).toList())
        .toList();
    tempStep = metadata['temperature_range']['step'] as double;
    salStep = metadata['salinity_range']['step'] as double;
    unit = metadata['unit'] as String;
  }

  double getO2Saturation(double temperature, double salinity) {
    if (!(0 <= temperature && temperature <= 40 && 0 <= salinity && salinity <= 40)) {
      throw ArgumentError('Temperature and salinity must be between 0 and 40');
    }

    // Calculate indices and fractional parts for interpolation
    final tempLowIdx = temperature ~/ tempStep; // Integer division for lower bound
    final tempHighIdx = (tempLowIdx + 1).clamp(0, matrix.length - 1);
    final tempLow = tempLowIdx * tempStep;
    final tempHigh = tempHighIdx * tempStep;
    final tempFraction = (temperature - tempLow) / tempStep;

    final salLowIdx = salinity ~/ salStep;
    final salHighIdx = (salLowIdx + 1).clamp(0, matrix[0].length - 1);
    final salLow = salLowIdx * salStep;
    final salHigh = salHighIdx * salStep;
    final salFraction = (salinity - salLow) / salStep;

    // Get the four corner values from the matrix
    final v00 = matrix[tempLowIdx][salLowIdx]; // Low temp, low salinity
    final v01 = matrix[tempLowIdx][salHighIdx]; // Low temp, high salinity
    final v10 = matrix[tempHighIdx][salLowIdx]; // High temp, low salinity
    final v11 = matrix[tempHighIdx][salHighIdx]; // High temp, high salinity

    // Perform bilinear interpolation
    final interpolatedValue = (1 - tempFraction) * (1 - salFraction) * v00 +
                              (1 - tempFraction) * salFraction * v01 +
                              tempFraction * (1 - salFraction) * v10 +
                              tempFraction * salFraction * v11;

    return interpolatedValue;
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
    return (saturationKgM3 * volume * efficiency * 100).floorToDouble() / 100; // Truncate to 2 decimals
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
  }) {
    final powerKw = (hp * 0.746 * 100).floorToDouble() / 100; // Truncate to 2 decimals
    final cs = getO2Saturation(temperature, salinity);
    final cs20 = getO2Saturation(20, salinity);
    final cs20KgM3 = cs20 * 0.001;

    final klaT = 1.0 / ((t70 - t10) / 60); // No 1.1 factor, keep t10/t70 as fractions
    final kla20 = klaT * pow(1.024, 20 - temperature).toDouble();

    final sotr = (kla20 * cs20KgM3 * volume * 100).floorToDouble() / 100; // Truncate to 2 decimals
    final sae = powerKw > 0 ? (sotr / powerKw * 100).floorToDouble() / 100 : 0; // Truncate to 2 decimals
    final costPerKg = sae > 0 ? (kwhPrice / sae * 100).floorToDouble() / 100 : double.infinity;

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