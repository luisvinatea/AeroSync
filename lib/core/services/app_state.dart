import 'package:flutter/material.dart';
import '../calculators/saturation_calculator.dart';
import 'calculator_service.dart';

class AppState extends ChangeNotifier {
  ShrimpPondCalculator? _calculator;
  bool _isLoading = true;
  String? _error;

  ShrimpPondCalculator? get calculator => _calculator;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initCalculator() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _calculator = await CalculatorServicePlatform.instance.initialize();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}