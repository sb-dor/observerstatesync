import 'package:flutter/material.dart';
import 'package:observerstatesynch/dependencies_scope.dart';
import 'package:observerstatesynch/internet_connection/internet_connection_controller.dart';

/// {@template internet_connection_widget}
/// InternetConnectionWidget widget.
/// {@endtemplate}
class InternetConnectionWidget extends StatefulWidget {
  /// {@macro internet_connection_widget}
  const InternetConnectionWidget({
    super.key, // ignore: unused_element_parameter
  });

  @override
  State<InternetConnectionWidget> createState() =>
      _InternetConnectionWidgetState();
}

/// State for widget InternetConnectionWidget.
class _InternetConnectionWidgetState extends State<InternetConnectionWidget>
    with InternetConnectionObserver {
  late final InternetConnectionController _internetConnectionController;

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    // Initial state initialization
    final dependencies = DependenciesScope.of(context);
    _internetConnectionController = dependencies.internetConnectionController;
    _internetConnectionController.addObserver(this);
  }

  @override
  void dispose() {
    // Permanent removal of a tree stent
    _internetConnectionController.removeObserver(this);
    super.dispose();
  }
  /* #endregion */

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
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('Internet connection observer')));
}
