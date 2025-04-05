import 'dart:convert';
import 'dart:math' show log, pow;
import 'package:flutter/services.dart' show rootBundle;

abstract class SaturationCalculator {
  Future<void> loadData();
  double getO2Saturation(double temperature, double salinity);
  Map<String, dynamic> calculateMetrics({
    required double temperature,
    required double salinity,
    required double horsepower,
    required double volume,
    required double t10,
    required double t70,
    required double kWhPrice,
    required String aeratorId,
  });
}

class ShrimpPondCalculator implements SaturationCalculator {
  final String dataPath;
  Map<String, dynamic>? _saturationData;

  ShrimpPondCalculator(this.dataPath);

  @override
  Future<void> loadData() async {
    try {
      final String jsonString = await rootBundle.loadString(dataPath);
      _saturationData = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load saturation data: $e');
    }
  }

  @override
  double getO2Saturation(double temperature, double salinity) {
    if (_saturationData == null) {
      throw Exception('Saturation data not loaded');
    }

    final tempIdx = temperature.round().toString();
    final salIdx = (salinity / 1.0).round().toString();

    if (_saturationData!.containsKey(tempIdx) &&
        (_saturationData![tempIdx] as Map).containsKey(salIdx)) {
      return double.parse(_saturationData![tempIdx][salIdx].toString());
    }

    return _interpolateSaturation(temperature, salinity);
  }

  double _interpolateSaturation(double temperature, double salinity) {
    return 7.0; // Default fallback
  }

  String _normalizeBrand(String brand) {
    const brandNormalization = {
      'pentair': 'Pentair', 'beraqua': 'Beraqua', 'maof madam': 'Maof Madam',
      'maofmadam': 'Maof Madam', 'cosumisa': 'Cosumisa', 'pioneer': 'Pioneer',
      'ecuasino': 'Ecuasino', 'diva': 'Diva', 'gps': 'GPS', 'wangfa': 'WangFa',
      'akva': 'AKVA', 'xylem': 'Xylem', 'newterra': 'Newterra', 'tsurumi': 'TSURUMI',
      'oxyguard': 'OxyGuard', 'linn': 'LINN', 'hunan': 'Hunan', 'sagar': 'Sagar',
      'hcp': 'HCP', 'yiyuan': 'Yiyuan', 'generic': 'Generic',
      'pentairr': 'Pentair', 'beraqua1': 'Beraqua', 'maof-madam': 'Maof Madam',
      'cosumissa': 'Cosumisa', 'pionner': 'Pioneer', 'ecuacino': 'Ecuasino',
      'divva': 'Diva', 'wang fa': 'WangFa', 'oxy guard': 'OxyGuard', 'lin': 'LINN',
      'sagr': 'Sagar', 'hcpp': 'HCP', 'yiyuan1': 'Yiyuan',
    };

    if (brand.isEmpty) return 'Generic';
    final brandLower = brand.toLowerCase().trim();
    return brandNormalization[brandLower] ?? brand;
  }

  @override
  Map<String, dynamic> calculateMetrics({
    required double temperature,
    required double salinity,
    required double horsepower,
    required double volume,
    required double t10,
    required double t70,
    required double kWhPrice,
    required String aeratorId,
  }) {
    final parts = aeratorId.split(' ');
    final brand = parts.length > 1 ? parts[0] : aeratorId;
    final aeratorType = parts.length > 1 ? parts.sublist(1).join(' ') : 'Unknown';
    final normalizedBrand = _normalizeBrand(brand);
    final normalizedAeratorId = '$normalizedBrand $aeratorType';

    final powerKw = (horsepower * 0.746 * 100).round() / 100;
    final cs = getO2Saturation(temperature, salinity);
    final cs20 = getO2Saturation(20, salinity);
    final cs20KgM3 = cs20 * 0.001;

    final klaT = 1.0 / ((t70 - t10) / 60);
    final kla20 = klaT * pow(1.024, 20 - temperature).toDouble();

    final sotr = (kla20 * cs20KgM3 * volume * 100).round() / 100;
    final sae = powerKw > 0 ? (sotr / powerKw * 100).round() / 100 : 0;
    final costPerKg = sae > 0 ? (kWhPrice / sae * 100).round() / 100 : double.infinity;

    return {
      'Pond Volume (m³)': volume,
      'Cs (mg/L)': cs,
      'KlaT (h⁻¹)': klaT,
      'Kla20 (h⁻¹)': kla20,
      'SOTR (kg O₂/h)': sotr,
      'SAE (kg O₂/kWh)': sae,
      'US\$/kg O₂': costPerKg, // Escaped $
      'Power (kW)': powerKw,
      'Normalized Aerator ID': normalizedAeratorId,
    };
  }
}