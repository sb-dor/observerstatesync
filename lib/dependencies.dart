import 'package:observerstatesynch/app_settings/app_settings_controller.dart';
import 'package:observerstatesynch/internet_connection/internet_connection_controller.dart';

class Dependencies {
  Dependencies({
    required this.appSettingsController,
    required this.internetConnectionController,
  });

  final AppSettingsController appSettingsController;
  final InternetConnectionController internetConnectionController;
}
