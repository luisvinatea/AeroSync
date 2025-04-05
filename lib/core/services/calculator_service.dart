import 'calculator_service_platform.dart';

class CalculatorService implements CalculatorServicePlatform {
  @override
  Future<ShrimpPondCalculator> initialize() async {
    const dataPath = 'assets/data/o2_temp_sal_100_sat.json';
    final calculator = ShrimpPondCalculator(dataPath);
    await calculator.loadData(); // Wait for data to load
    return calculator;
  }
}