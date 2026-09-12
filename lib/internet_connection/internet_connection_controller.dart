import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum InternetStatus { checking, online, offline }

/// Signature of the DNS lookup used to probe connectivity; injectable for
/// tests so no real network access (or pending timers) is required.
typedef InternetAddressLookup = Future<List<InternetAddress>> Function(
  String host,
);

mixin InternetConnectionObserver {
  void onInternetConnectionChange(InternetStatus status) {}
}

class InternetConnectionController with ChangeNotifier {
  InternetConnectionController({
    this.checkInterval = const Duration(seconds: 5),
    this.lookupTimeout = const Duration(seconds: 3),
    InternetAddressLookup? lookup,
  }) : _lookup = lookup ?? InternetAddress.lookup {
    checkInternet();

    _timer = Timer.periodic(checkInterval, (_) => checkInternet());
  }

  final Duration checkInterval;

  final Duration lookupTimeout;

  final InternetAddressLookup _lookup;

  // Store observers in a Set, preventing duplicates. Unlike list of observers
  final _observers = <InternetConnectionObserver>{};

  Timer? _timer;
  bool _checkInProgress = false;
  bool _disposed = false;

  InternetStatus _status = InternetStatus.checking;

  InternetStatus get status => _status;

  bool get isOnline => _status == InternetStatus.online;

  void addObserver(InternetConnectionObserver observer) =>
      _observers.add(observer);

  void removeObserver(InternetConnectionObserver observer) =>
      _observers.remove(observer);

  Future<void> checkInternet() async {
    if (_checkInProgress || _disposed) return;

    _checkInProgress = true;
    InternetStatus newStatus;

    try {
      final addresses = await _lookup('example.com')
          .timeout(lookupTimeout);

      newStatus = addresses.isNotEmpty
          ? InternetStatus.online
          : InternetStatus.offline;
    } on SocketException {
      newStatus = InternetStatus.offline;
    } on TimeoutException {
      newStatus = InternetStatus.offline;
    } catch (_) {
      newStatus = InternetStatus.offline;
    }

    _checkInProgress = false;

    if (!_disposed && _status != newStatus) {
      _status = newStatus;
      notifyListeners();
      for (final observer in _observers) {
        observer.onInternetConnectionChange(_status);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
