import 'package:flutter/services.dart';
import '../calculators/saturation_calculator.dart';

abstract class CalculatorServicePlatform {
  Future<ShrimpPondCalculator> initialize();
  
  static CalculatorServicePlatform get instance {
    return CalculatorService();
  }
}