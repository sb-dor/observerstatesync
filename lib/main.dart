import 'package:flutter/material.dart';
import 'package:observerstatesynch/app_settings_controller.dart';
import 'package:observerstatesynch/dependencies.dart';
import 'package:observerstatesynch/dependencies_scope.dart';
import 'package:observerstatesynch/internet_connection_controller.dart';

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
      home: DependenciesScope(dependencies: dependencies, child: App()),
    );
  }
}

/// {@template main}
/// App widget.
/// {@endtemplate}
class App extends StatefulWidget {
  /// {@macro main}
  const App({
    super.key, // ignore: unused_element_parameter
  });

  @override
  State<App> createState() => _AppState();
}

/// State for widget App.
class _AppState extends State<App>
    with AppSettingsObserver, InternetConnectionObserver {
  late final AppSettingsController _appSettingsController;
  late final InternetConnectionController _internetConnectionController;

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    final dependencies = DependenciesScope.of(context);
    _appSettingsController = dependencies.appSettingsController;
    _internetConnectionController = dependencies.internetConnectionController;

    _appSettingsController.addObserver(this);
    _internetConnectionController.addObserver(this);
  }

  @override
  void dispose() {
    // Permanent removal of a tree stent
    _appSettingsController.removeObserver(this);
    _internetConnectionController.removeObserver(this);
    super.dispose();
  }
  /* #endregion */

  @override
  void onNotificationChange(bool notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification ${notification ? 'enabled' : 'disabled'}'),
      ),
    );
  }

  @override
  void onInternetConnectionChange(InternetStatus status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Internet connection is ${status.name}'),
        backgroundColor: switch (status) {
          InternetStatus.online => Colors.green,
          _ => Colors.red,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Sync state with observers')),
    body: Column(
      children: [
        ListenableBuilder(
          listenable: _appSettingsController,
          builder: (context, _) => Switch.adaptive(
            value: _appSettingsController.notifications,
            onChanged: (_) {
              _appSettingsController.changeNotification();
            },
          ),
        ),
      ],
    ),
  );
}
