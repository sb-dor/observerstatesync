import 'package:flutter/widgets.dart';

enum AppLifecycleStatus { resumed, inactive, hidden, paused, detached }

/// Extended observer: any screen or service can subscribe to app lifecycle
/// events without implementing [WidgetsBindingObserver] itself.
mixin AppLifecycleObserver {
  void onAppLifecycleChange(AppLifecycleStatus status) {}
}

/// Subject of the observer pattern. Extends the classic scheme by also
/// mixing in [WidgetsBindingObserver], so the framework's own observer
/// events are adapted and re-broadcast to our custom observers.
class AppLifecycleController with ChangeNotifier, WidgetsBindingObserver {
  // Store observers in a Set, preventing duplicates. Unlike list of observers
  final _observers = <AppLifecycleObserver>{};

  AppLifecycleStatus _status = AppLifecycleStatus.resumed;

  AppLifecycleController() {
    WidgetsBinding.instance.addObserver(this);
  }

  AppLifecycleStatus get status => _status;

  bool get isResumed => _status == AppLifecycleStatus.resumed;

  void addObserver(AppLifecycleObserver observer) => _observers.add(observer);

  void removeObserver(AppLifecycleObserver observer) =>
      _observers.remove(observer);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final AppLifecycleStatus newStatus = switch (state) {
      AppLifecycleState.resumed => AppLifecycleStatus.resumed,
      AppLifecycleState.inactive => AppLifecycleStatus.inactive,
      AppLifecycleState.hidden => AppLifecycleStatus.hidden,
      AppLifecycleState.paused => AppLifecycleStatus.paused,
      AppLifecycleState.detached => AppLifecycleStatus.detached,
    };

    if (_status == newStatus) return;

    _status = newStatus;
    notifyListeners();
    for (final observer in _observers) {
      observer.onAppLifecycleChange(_status);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _observers.clear();
    super.dispose();
  }
}
