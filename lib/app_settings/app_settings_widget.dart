import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:observerstatesynch/app_settings/app_settings_controller.dart';
import 'package:observerstatesynch/dependencies_scope.dart';

/// {@template app_settings_widget}
/// AppSettingsWidget widget.
/// {@endtemplate}
class AppSettingsWidget extends StatefulWidget {
  /// {@macro app_settings_widget}
  const AppSettingsWidget({
    super.key, // ignore: unused_element_parameter
  });

  @override
  State<AppSettingsWidget> createState() => _AppSettingsWidgetState();
}

/// State for widget AppSettingsWidget.
class _AppSettingsWidgetState extends State<AppSettingsWidget>
    with AppSettingsObserver {
  late final AppSettingsController _appSettingsController;

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    // Initial state initialization
    final dependencies = DependenciesScope.of(context);
    _appSettingsController = dependencies.appSettingsController;

    _appSettingsController.addObserver(this);
  }

  @override
  void dispose() {
    // Permanent removal of a tree stent
    _appSettingsController.removeObserver(this);
    super.dispose();
  }
  /* #endregion */

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
