import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../widgets/calculator_form.dart' as calc_form;
import '../widgets/results_display.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AeraSync Calculator'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // Allow gestures to pass through
        onScaleStart: (_) {}, // Required to enable scale gestures
        onScaleUpdate: (_) {}, // Required to enable scale gestures
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF60A5FA),
                Color(0xFF1E40AF),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: appState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : appState.error != null
                    ? Center(child: Text('Error: ${appState.error}', style: const TextStyle(color: Colors.white)))
                    : Column(
                        children: [
                          // Calculator Form
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: SingleChildScrollView(
                              child: calc_form.CalculatorForm(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Results Display
                          Expanded(
                            child: ResultsDisplay(),
                          ),
                          // Disclaimer
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Disclaimer: AeraSync is not affiliated with any aerator brands. Brand names entered by users are for informational purposes only and do not imply endorsement or official data from the manufacturers.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}