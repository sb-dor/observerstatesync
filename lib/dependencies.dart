import 'package:observerstatesynch/app_lifecycle/app_lifecycle_controller.dart';
import 'package:observerstatesynch/app_settings/app_settings_controller.dart';
import 'package:observerstatesynch/internet_connection/internet_connection_controller.dart';
import 'package:observerstatesynch/superlist/task_list_controller.dart';

class Dependencies {
  Dependencies({
    required this.appSettingsController,
    required this.internetConnectionController,
    required this.appLifecycleController,
    required this.taskListController,
  });

  final AppSettingsController appSettingsController;
  final InternetConnectionController internetConnectionController;
  final AppLifecycleController appLifecycleController;
  final TaskListController taskListController;
}
