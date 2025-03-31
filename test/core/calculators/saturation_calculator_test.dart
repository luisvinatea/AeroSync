import 'package:flutter_test/flutter_test.dart';
import 'package:aerosync/core/calculators/saturation_calculator.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShrimpPondCalculator', () {
    late ShrimpPondCalculator calculator;

    setUp(() async {
      const testData = '''
      {
        "metadata": {
          "unit": "mg/L",
          "temperature_range": {"min": 0, "max": 40, "step": 1},
          "salinity_range": {"min": 0, "max": 40, "step": 1}
        },
        "data": [
          [8.0, 8.1, 8.2],
          [7.9, 8.0, 8.1],
          [7.8, 7.9, 8.0]
        ]
      }
      ''';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'),
              (methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
          return './test_temp';
        }
        return null;
      });

      final file = File('./test_temp/o2_data.json');
      await file.create(recursive: true);
      await file.writeAsString(testData);

      calculator = ShrimpPondCalculator(file.path);
    });

    test('getO2Saturation returns correct values', () {
      expect(calculator.getO2Saturation(0, 0), 8.0);
      expect(calculator.getO2Saturation(1, 1), 8.0);
    });

    test('calculateSotr computes correct value', () {
      expect(
        calculator.calculateSotr(0, 0, 1000),
        closeTo(8.0 * 0.001 * 1000 * 0.9, 0.001),
      );
    });
  });
}