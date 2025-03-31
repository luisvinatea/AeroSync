// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AeraSync';

  @override
  String get calculate => 'Calculate';

  @override
  String get temperature => 'Temperature';

  @override
  String get salinity => 'Salinity';

  @override
  String get errorInvalidInput => 'Invalid input';
}
