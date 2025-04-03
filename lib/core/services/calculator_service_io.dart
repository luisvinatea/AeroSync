import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'calculator_service_platform.dart';
import '../calculators/saturation_calculator.dart';

class CalculatorService extends CalculatorServicePlatform {
  @override
  Future<ShrimpPondCalculator> initialize() async {
    final data = await rootBundle.loadString('assets/data/o2_temp_sal_100_sat.json');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/o2_data.json');
    await file.writeAsString(data);
    final calculator = ShrimpPondCalculator(file.path);
    await calculator.loadData(); // Ensure data is loaded before returning
    return calculator;
  }
}