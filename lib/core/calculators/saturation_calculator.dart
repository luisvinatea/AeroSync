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
  List<List<double>>? _matrix;
  double _tempStep = 1.0;
  double _salStep = 5.0;

  ShrimpPondCalculator(this.dataPath);

  @override
  Future<void> loadData() async {
    try {
      final String jsonString = await rootBundle.loadString(dataPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = data['metadata'] as Map<String, dynamic>;
      _matrix = (data['data'] as List)
          .map((row) => (row as List).map((e) => e as double).toList())
          .toList();
      _tempStep = (metadata['temperature_range']['step'] as num).toDouble();
      _salStep = (metadata['salinity_range']['step'] as num).toDouble();
    } catch (e) {
      throw Exception('Failed to load saturation data: $e');
    }
  }

  @override
  double getO2Saturation(double temperature, double salinity) {
    if (_matrix == null) throw Exception('Saturation data not loaded');
    if (!(0 <= temperature && temperature <= 40 && 0 <= salinity && salinity <= 40)) {
      throw ArgumentError('Temperature and salinity must be between 0 and 40');
    }
    final tempIdx = temperature.round();
    final salIdx = (salinity / _salStep).floor();
    if (tempIdx >= _matrix!.length || salIdx >= _matrix![0].length) {
      throw RangeError('Index out of bounds: tempIdx=$tempIdx, salIdx=$salIdx');
    }
    return _matrix![tempIdx][salIdx];
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
    return brandNormalization[brand.toLowerCase().trim()] ?? (brand.isEmpty ? 'Generic' : brand);
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

    final deltaT = (t70 - t10) / 60; // Convert to hours
    final klaT = deltaT > 0 ? 1.099 / deltaT : double.infinity; // h⁻¹
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
      'US\$/kg O₂': costPerKg,
      'Power (kW)': powerKw,
      'Normalized Aerator ID': normalizedAeratorId,
    };
  }
}