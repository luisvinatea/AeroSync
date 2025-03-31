import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/calculators/saturation_calculator.dart';

class CalculatorForm extends StatefulWidget {
  const CalculatorForm({super.key});

  @override
  State<CalculatorForm> createState() => _CalculatorFormState();
}

class _CalculatorFormState extends State<CalculatorForm> {
  final _formKey = GlobalKey<FormState>();
  final _tempController = TextEditingController(text: '30');
  final _salinityController = TextEditingController(text: '20');
  final _hpController = TextEditingController(text: '3');
  final _volumeController = TextEditingController(text: '50');
  final _t10Controller = TextEditingController(text: '5');
  final _t70Controller = TextEditingController(text: '20');
  final _kwhController = TextEditingController(text: '0.12');
  String _selectedAerator = 'Generic Paddlewheel';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Card(
      elevation: 4, // Slight shadow for depth
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: appState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : appState.error != null
                ? Center(child: Text('Error: ${appState.error}', style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aerator Performance Calculator',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(_tempController, 'Temperature (°C)', 0, 40),
                          _buildTextField(_salinityController, 'Salinity (‰)', 0, 40),
                          _buildTextField(_hpController, 'Horsepower (HP)', 0, 100),
                          _buildTextField(_volumeController, 'Volume (m³)', 0, 1000),
                          _buildTextField(_t10Controller, 'T10 (minutes)', 0, 60),
                          _buildTextField(_t70Controller, 'T70 (minutes)', 0, 60),
                          _buildTextField(_kwhController, 'Electricity Cost (\$/kWh)', 0, 1),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedAerator,
                            items: ShrimpPondCalculator.sotrPerHp.keys.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedAerator = value!),
                            decoration: InputDecoration(
                              labelText: 'Aerator Type',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: appState.calculator != null ? _calculate : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Calculate', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, double min, double max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        keyboardType: TextInputType.number,
        validator: (value) => _validateInput(value, min, max),
      ),
    );
  }

  String? _validateInput(String? value, double min, double max) {
    if (value == null || value.isEmpty) return 'Required';
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Invalid number';
    if (numValue < min || numValue > max) return 'Must be between $min and $max';
    return null;
  }

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      final calculator = appState.calculator!;
      final metrics = calculator.calculateMetrics(
        temperature: double.parse(_tempController.text),
        salinity: double.parse(_salinityController.text),
        hp: double.parse(_hpController.text),
        volume: double.parse(_volumeController.text),
        t10: double.parse(_t10Controller.text),
        t70: double.parse(_t70Controller.text),
        kwhPrice: double.parse(_kwhController.text),
        aeratorId: _selectedAerator,
      );
      _showResultsDialog(metrics);
    }
  }

  void _showResultsDialog(Map<String, dynamic> metrics) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculation Results', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: metrics.entries.map((e) {
              final value = e.value is double ? e.value.toStringAsFixed(2) : e.value.toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(value, textAlign: TextAlign.right)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _tempController.dispose();
    _salinityController.dispose();
    _hpController.dispose();
    _volumeController.dispose();
    _t10Controller.dispose();
    _t70Controller.dispose();
    _kwhController.dispose();
    super.dispose();
  }
}