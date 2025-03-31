import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../calculators/saturation_calculator.dart';

class CalculatorService {
  static Future<ShrimpPondCalculator> initialize() async {
    try {
      final data = await rootBundle.loadString('assets/data/o2_temp_sal_100_sat.json');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/o2_data.json');
      await file.writeAsString(data);
      return ShrimpPondCalculator(file.path);
    } catch (e) {
      throw Exception('Failed to initialize calculator: ${e.toString()}');
    }
  }
}