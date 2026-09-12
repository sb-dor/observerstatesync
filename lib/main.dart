import 'package:flutter/material.dart';
import 'package:observerstatesynch/app_lifecycle/app_lifecycle_controller.dart';
import 'package:observerstatesynch/app_settings/app_settings_controller.dart';
import 'package:observerstatesynch/dependencies.dart';
import 'package:observerstatesynch/dependencies_scope.dart';
import 'package:observerstatesynch/home_page.dart';
import 'package:observerstatesynch/internet_connection/internet_connection_controller.dart';
import 'package:observerstatesynch/superlist/task_list_controller.dart';

void main() {
  // Ensures the WidgetsBinding exists before controllers that observe the
  // binding (e.g. AppLifecycleController) are constructed below.
  WidgetsFlutterBinding.ensureInitialized();

  final internetConnectionController = InternetConnectionController();
  final dependencies = Dependencies(
    appSettingsController: AppSettingsController(),
    internetConnectionController: internetConnectionController,
    appLifecycleController: AppLifecycleController(),
    taskListController: TaskListController(
      internetConnectionController: internetConnectionController,
    ),
  );
  runApp(MyApp(dependencies: dependencies));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // The scope wraps MaterialApp (not just home) so that every pushed
    // Navigator route can resolve Dependencies via DependenciesScope.of.
    return DependenciesScope(
      dependencies: dependencies,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
        home: HomePage(),
      ),
    );
  }
}
