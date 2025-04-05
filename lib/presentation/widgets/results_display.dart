import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show exp; // Import exp from dart:math
import '../../core/services/app_state.dart';

class ResultsDisplay extends StatelessWidget {
  const ResultsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.results == null || appState.results!.isEmpty) {
          return const Center(
            child: Text(
              'Enter values and click Calculate to see results',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final results = appState.results!;
        final inputs = appState.inputs!;

        return ListView(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white.withOpacity(0.9),
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Metrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...results.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                _formatValue(entry.value),
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    const Text(
                      'Saturation Over Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: _buildSaturationChart(results, inputs),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadAsCsv(inputs, results),
                        icon: const Icon(Icons.download, size: 32),
                        label: const Text('Download as CSV'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      if (['SOTR (kg O₂/h)', 'SAE (kg O₂/kWh)', 'US\$/kg O₂', 'Power (kW)'].contains(value)) {
        return value.toStringAsFixed(2);
      }
      return value.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return value.toString();
  }

  Widget _buildSaturationChart(Map<String, dynamic> results, Map<String, dynamic> inputs) {
    final double klaT = results['KlaT (h⁻¹)'] as double;
    final double t10 = (inputs['T10 (minutes)'] as double) / 60; // Cast first, then divide
    final double t70 = (inputs['T70 (minutes)'] as double) / 60; // Cast first, then divide

    // Generate saturation curve data (0 to 24 hours)
    final List<FlSpot> saturationSpots = [];
    for (double t = 0; t <= 24; t += 0.5) {
      final double saturationPercent = (1 - exp(-klaT * t)) * 100;
      saturationSpots.add(FlSpot(saturationPercent, t));
    }

    // Pinpoints for t10 and t70
    final FlSpot t10Spot = FlSpot(10, t10);
    final FlSpot t70Spot = FlSpot(70, t70);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()} h',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            axisNameWidget: const Text('Time (hours)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            axisNameWidget: const Text('Saturation (%)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey)),
        minX: 0,
        maxX: 100,
        minY: 0,
        maxY: 24,
        lineBarsData: [
          LineChartBarData(
            spots: saturationSpots,
            isCurved: true,
            color: const Color(0xFF1E40AF),
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: [t10Spot],
            color: Colors.red,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 5,
                color: Colors.red,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
          ),
          LineChartBarData(
            spots: [t70Spot],
            color: Colors.green,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 5,
                color: Colors.green,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(y: t10, color: Colors.red.withOpacity(0.5), strokeWidth: 1, dashArray: [5, 5]),
            HorizontalLine(y: t70, color: Colors.green.withOpacity(0.5), strokeWidth: 1, dashArray: [5, 5]),
          ],
          verticalLines: [
            VerticalLine(x: 10, color: Colors.red.withOpacity(0.5), strokeWidth: 1, dashArray: [5, 5]),
            VerticalLine(x: 70, color: Colors.green.withOpacity(0.5), strokeWidth: 1, dashArray: [5, 5]),
          ],
        ),
      ),
    );
  }

  void _downloadAsCsv(Map<String, dynamic> inputs, Map<String, dynamic> results) {
    final combinedData = <String, dynamic>{};
    
    inputs.forEach((key, value) {
      combinedData['Input: $key'] = value;
    });

    results.forEach((key, value) {
      combinedData['Result: $key'] = value;
    });

    final csvRows = <String>[];
    csvRows.add('"Category","Value"');

    combinedData.forEach((key, value) {
      final escapedKey = key.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_data_${DateTime.now().toIso8601String()}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}