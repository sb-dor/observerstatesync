import 'package:flutter/foundation.dart';

mixin AppSettingsObserver {
  void onNotificationChange(bool notification) {}
}

class AppSettingsController with ChangeNotifier {
  final _observers = <AppSettingsObserver>[];

  bool _notifications = false;

  bool get notifications => _notifications;

  void addObserver(AppSettingsObserver observer) => _observers.add(observer);

  void removeObserver(AppSettingsObserver observer) =>
      _observers.remove(observer);

  void changeNotification() {
    _notifications = !_notifications;
    notifyListeners();
    for (final observer in _observers) {
      observer.onNotificationChange(_notifications);
    }
  }
}
