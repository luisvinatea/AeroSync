import 'package:flutter/foundation.dart';
import '../../core/calculators/saturation_calculator.dart';

class AppState with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  ShrimpPondCalculator? _calculator; // Explicitly typed as ShrimpPondCalculator
  Map<String, dynamic>? _results;
  Map<String, dynamic>? _inputs;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ShrimpPondCalculator? get calculator => _calculator; // Updated getter type
  Map<String, dynamic>? get results => _results;
  Map<String, dynamic>? get inputs => _inputs;

  Future<void> initCalculator() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final calculator = ShrimpPondCalculator('assets/data/o2_temp_sal_100_sat.json');
      await calculator.loadData(); // Ensure data is loaded before use
      _calculator = calculator;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize calculator: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setResults(Map<String, dynamic>? results, Map<String, dynamic>? inputs) {
    _results = results;
    _inputs = inputs;
    notifyListeners();
  }
}