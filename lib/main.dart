import 'package:flutter/material.dart';
import 'package:observerstatesynch/app_settings/app_settings_controller.dart';
import 'package:observerstatesynch/app_settings/app_settings_widget.dart';
import 'package:observerstatesynch/dependencies.dart';
import 'package:observerstatesynch/dependencies_scope.dart';
import 'package:observerstatesynch/internet_connection/internet_connection_controller.dart';

void main() {
  final dependencies = Dependencies(
    appSettingsController: AppSettingsController(),
    internetConnectionController: InternetConnectionController(),
  );
  runApp(MyApp(dependencies: dependencies));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.dependencies});

  final Dependencies dependencies;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: DependenciesScope(
        dependencies: dependencies,
        child: AppSettingsWidget(),
      ),
    );
  }
}
