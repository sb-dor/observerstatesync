import 'package:flutter/material.dart';
import 'package:observerstatesynch/app_lifecycle/app_lifecycle_widget.dart';
import 'package:observerstatesynch/app_settings/app_settings_widget.dart';
import 'package:observerstatesynch/internet_connection/internet_connection_widget.dart';
import 'package:observerstatesynch/superlist/task_list_widget.dart';

/// Root page listing all observer-pattern demo screens.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Sync state with observers')),
    body: ListView(
      children: [
        ListTile(
          title: Text('App settings observer'),
          subtitle: Text('Notifications switch'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _open(context, const AppSettingsWidget()),
        ),
        ListTile(
          title: Text('Internet connection observer'),
          subtitle: Text('Connectivity status'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _open(context, const InternetConnectionWidget()),
        ),
        ListTile(
          title: Text('App lifecycle observer'),
          subtitle: Text('App foreground/background status'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _open(context, const AppLifecycleWidget()),
        ),
        ListTile(
          title: Text('Superlist demo'),
          subtitle: Text('Tasks, subtasks, offline sync, activity feed'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _open(context, const TaskListWidget()),
        ),
      ],
    ),
  );

  void _open(BuildContext context, Widget widget) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => widget),
    );
  }
}