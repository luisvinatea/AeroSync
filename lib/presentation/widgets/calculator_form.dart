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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tempController,
                decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                keyboardType: TextInputType.number,
                validator: (value) => _validateInput(value, 0, 40),
              ),
              TextFormField(
                controller: _salinityController,
                decoration: const InputDecoration(labelText: 'Salinity (‰)'),
                keyboardType: TextInputType.number,
                validator: (value) => _validateInput(value, 0, 40),
              ),
              TextFormField(
                controller: _hpController,
                decoration: const InputDecoration(labelText: 'Horsepower (HP)'),
                keyboardType: TextInputType.number,
                validator: (value) => _validateInput(value, 0, 100),
              ),
              TextFormField(
                controller: _volumeController,
                decoration: const InputDecoration(labelText: 'Volume (m³)'),
                keyboardType: TextInputType.number,
                validator: (value) => _validateInput(value, 0, 1000),
              ),
              TextFormField(
                controller: _t10Controller,
                decoration: const InputDecoration(labelText: 'T10 (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) => _validateInput(value, 0, 60),
              ),
              TextFormField(
                controller: _t70Controller,
                decoration: const InputDecoration(labelText: 'T70 (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) => _validateInput(value, 0, 60),
              ),
              TextFormField(
                controller: _kwhController,
                decoration: const InputDecoration(labelText: 'Electricity Cost (\$/kWh)'),
                keyboardType: TextInputType.number,
                validator: (value) => _validateInput(value, 0, 1),
              ),
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
                decoration: const InputDecoration(labelText: 'Aerator Type'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ],
          ),
        ),
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
      final calculator = appState.calculator;
      if (calculator != null) {
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
        // TODO: Display results
      }
    }
  }
}