import 'package:flutter/foundation.dart';
import '../calculators/saturation_calculator.dart';

class AppState with ChangeNotifier {
  ShrimpPondCalculator? _calculator;
  Map<String, dynamic>? _results;
  Map<String, dynamic>? _inputs;
  bool _isLoading = false;
  String? _error;

  AppState() {
    initCalculator();
  }

  ShrimpPondCalculator? get calculator => _calculator;
  Map<String, dynamic>? get results => _results;
  Map<String, dynamic>? get inputs => _inputs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initCalculator() async {
    _isLoading = true;
    notifyListeners();
    try {
      final calculator = ShrimpPondCalculator('assets/data/o2_temp_sal_100_sat.json');
      await calculator.loadData();
      _calculator = calculator;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setResults(Map<String, dynamic> results, Map<String, dynamic> inputs) {
    _results = results;
    _inputs = inputs;
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    _results = null;
    _inputs = null;
    notifyListeners();
  }
}