import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'calculator_service_platform.dart';
import '../calculators/saturation_calculator.dart';

class CalculatorService extends CalculatorServicePlatform {
  @override
  Future<ShrimpPondCalculator> initialize() async {
    final data = await rootBundle.loadString('assets/data/o2_temp_sal_100_sat.json');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/o2_data.json');
    await file.writeAsString(data);
    return ShrimpPondCalculator(file.path);
  }
}