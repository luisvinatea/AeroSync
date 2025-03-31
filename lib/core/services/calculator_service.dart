import 'calculator_service_platform.dart';
import '../calculators/saturation_calculator.dart';
import 'package:flutter/services.dart' show rootBundle;

class CalculatorService implements CalculatorServicePlatform {
  @override
  Future<ShrimpPondCalculator> initialize() async {
    const dataPath = 'assets/data/o2_temp_sal_100_sat.json';
    final calculator = ShrimpPondCalculator(dataPath);
    await calculator.loadData(); // Wait for data to load
    return calculator;
  }
}