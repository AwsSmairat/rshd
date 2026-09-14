import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/network/api_exception.dart';
import 'package:rshd/features/profile/data/models/profile_model.dart';
import 'package:rshd/features/profile/data/profile_repository.dart';
import 'package:rshd/features/profile/presentation/profile_controller.dart';

class _ControlledProfileRepository implements ProfileRepository {
  final Completer<ProfileModel> request = Completer<ProfileModel>();

  @override
  Future<ProfileModel> getProfile() => request.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'profile controller ignores a late API failure after disposal',
    () async {
      final repository = _ControlledProfileRepository();
      final controller = ProfileController(repository);

      final loadFuture = controller.load();

      controller.dispose();

      repository.request.completeError(
        ApiException(message: 'session expired', statusCode: 401),
      );

      await expectLater(loadFuture, completes);
    },
  );
}
