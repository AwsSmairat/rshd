import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/network/api_exception.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/presentation/auth_controller.dart';

class _DeviceMismatchAuthRepository implements AuthRepository {
  _DeviceMismatchAuthRepository(this._error);

  final ApiException _error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    throw _error;
  }
}

void main() {
  const deviceMessage =
      'هذا الحساب متصل على جهاز آخر، يرجى التواصل مع الإدارة لإعادة تعيين الجهاز.';

  test('login maps device mismatch error code to Arabic message', () async {
    final controller = AuthController(
      _DeviceMismatchAuthRepository(
        ApiException(
          message: deviceMessage,
          statusCode: 403,
          errorCode: 'device_mismatch',
        ),
      ),
    );

    final result = await controller.login(
      email: 'student@rshd.test',
      password: 'password',
    );

    expect(result, LoginFlowResult.failed);
    expect(controller.state.errorMessage, deviceMessage);
    expect(controller.state.fieldErrors, isEmpty);
  });

  test('login hides email field error for device mismatch message', () async {
    final controller = AuthController(
      _DeviceMismatchAuthRepository(
        ApiException(message: deviceMessage, statusCode: 403),
      ),
    );

    await controller.login(email: 'student@rshd.test', password: 'password');

    expect(controller.state.errorMessage, deviceMessage);
    expect(controller.state.fieldErrors, isEmpty);
  });

  test(
    'login maps incorrect credentials to Arabic banner and field error',
    () async {
      final controller = AuthController(
        _DeviceMismatchAuthRepository(
          ApiException(
            message: 'The given data was invalid.',
            statusCode: 422,
            errors: {
              'email': ['The provided credentials are incorrect.'],
            },
          ),
        ),
      );

      await controller.login(email: 'student@rshd.test', password: 'wrong');

      expect(controller.state.errorMessage, 'بيانات الدخول غير صحيحة.');
      expect(controller.state.fieldErrors['email'], 'بيانات الدخول غير صحيحة.');
    },
  );
}
