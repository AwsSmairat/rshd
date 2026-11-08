import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticks each time the API answers "under maintenance" (HTTP 503 with
/// `maintenance: true`), so the app can switch to the maintenance screen
/// even when maintenance began after it was opened.
class MaintenanceSignalNotifier extends StateNotifier<int> {
  MaintenanceSignalNotifier() : super(0);

  void notifyMaintenance() {
    state++;
  }
}

final maintenanceSignalProvider =
    StateNotifierProvider<MaintenanceSignalNotifier, int>((ref) {
      return MaintenanceSignalNotifier();
    });
