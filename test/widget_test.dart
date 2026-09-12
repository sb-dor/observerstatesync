// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:observerstatesynch/app_lifecycle/app_lifecycle_controller.dart';

class _RecordingObserver with AppLifecycleObserver {
  final statuses = <AppLifecycleStatus>[];

  @override
  void onAppLifecycleChange(AppLifecycleStatus status) => statuses.add(status);
}

void main() {
  testWidgets(
    'AppLifecycleController notifies observers on lifecycle changes',
    (tester) async {
      final controller = AppLifecycleController();
      addTearDown(controller.dispose);
      final observer = _RecordingObserver();
      controller.addObserver(observer);

      // Emulate the app going to background: resumed -> inactive -> hidden
      // -> paused (the sequence the engine sends).
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

      expect(
        observer.statuses,
        [
          AppLifecycleStatus.inactive,
          AppLifecycleStatus.hidden,
          AppLifecycleStatus.paused,
        ],
      );
      expect(controller.status, AppLifecycleStatus.paused);
      expect(controller.isResumed, isFalse);

      // No duplicate notifications for the same state.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(observer.statuses.length, 3);

      // Removing the observer stops the notifications.
      controller.removeObserver(observer);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      expect(observer.statuses.length, 3);
    },
  );
}
