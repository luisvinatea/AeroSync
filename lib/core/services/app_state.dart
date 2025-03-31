import 'package:AeraSync/core/services/calculator_service_platform.dart';
import 'package:flutter/material.dart'; // Add this for ChangeNotifier
import '../calculators/saturation_calculator.dart';
// No need for calculator_service_interface.dart unless you're using it elsewhere

class AppState extends ChangeNotifier {
  ShrimpPondCalculator? _calculator;
  bool _isLoading = true;
  String? _error;

  ShrimpPondCalculator? get calculator => _calculator;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AppState() {
    initCalculator(); // Call this in the constructor if you want it to initialize on creation
  }

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