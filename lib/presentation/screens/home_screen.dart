import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../widgets/calculator_form.dart';
import '../widgets/results_display.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AeroSync Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: appState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : appState.error != null
                ? Center(child: Text('Error: ${appState.error}'))
                : const Column(
                    children: [
                      CalculatorForm(),
                      SizedBox(height: 20),
                      Expanded(child: ResultsDisplay()),
                    ],
                  ),
      ),
    );
  }
}