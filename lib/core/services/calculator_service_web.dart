import 'package:flutter/services.dart' show rootBundle;
import 'calculator_service_platform.dart';

class CalculatorService extends CalculatorServicePlatform {
  @override
  Future<ShrimpPondCalculator> initialize() async {
    final data = await rootBundle.loadString('assets/data/o2_temp_sal_100_sat.json');
    final calculator = ShrimpPondCalculator('assets/data/o2_temp_sal_100_sat.json');
    await calculator.loadData(); // Ensure data is loaded before returning
    return calculator;
  }
}