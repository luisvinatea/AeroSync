import 'dart:convert';
import 'package:flutter/services.dart';
import 'calculator_service_platform.dart';
import '../calculators/saturation_calculator.dart';

class CalculatorService extends CalculatorServicePlatform {
  @override
  Future<ShrimpPondCalculator> initialize() async {
    final data = await rootBundle.loadString('assets/data/o2_temp_sal_100_sat.json');
    return ShrimpPondCalculator.fromJson(jsonDecode(data));
  }
}