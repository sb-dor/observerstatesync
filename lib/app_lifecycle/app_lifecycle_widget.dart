import 'package:flutter/material.dart';
import 'package:observerstatesynch/app_lifecycle/app_lifecycle_controller.dart';
import 'package:observerstatesynch/dependencies_scope.dart';

/// {@template app_lifecycle_widget}
/// AppLifecycleWidget widget.
/// {@endtemplate}
class AppLifecycleWidget extends StatefulWidget {
  /// {@macro app_lifecycle_widget}
  const AppLifecycleWidget({
    super.key,
  });

  @override
  State<AppLifecycleWidget> createState() => _AppLifecycleWidgetState();
}

/// State for widget AppLifecycleWidget.
class _AppLifecycleWidgetState extends State<AppLifecycleWidget>
    with AppLifecycleObserver {
  late final AppLifecycleController _appLifecycleController;

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    // Initial state initialization
    final dependencies = DependenciesScope.of(context);
    _appLifecycleController = dependencies.appLifecycleController;

    _appLifecycleController.addObserver(this);
  }

  @override
  void dispose() {
    // Permanent removal of a tree stent
    _appLifecycleController.removeObserver(this);
    super.dispose();
  }
  /* #endregion */

  @override
  void onAppLifecycleChange(AppLifecycleStatus status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('App lifecycle is ${status.name}'),
        backgroundColor: switch (status) {
          AppLifecycleStatus.resumed => Colors.green,
          _ => Colors.orange,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('App lifecycle observer')),
    body: Center(
      child: ListenableBuilder(
        listenable: _appLifecycleController,
        builder: (context, _) => Text(
          'Current status: ${_appLifecycleController.status.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ),
  );
}
