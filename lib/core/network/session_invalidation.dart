import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionInvalidationNotifier extends StateNotifier<int> {
  SessionInvalidationNotifier() : super(0);

  void notifyUnauthorized() {
    state++;
  }
}

final sessionInvalidationProvider =
    StateNotifierProvider<SessionInvalidationNotifier, int>((ref) {
      return SessionInvalidationNotifier();
    });
