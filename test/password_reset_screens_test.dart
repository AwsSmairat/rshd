import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/core/device/device_service.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/features/auth/data/auth_repository.dart';
import 'package:rshd/features/auth/presentation/forgot_password_screen.dart';
import 'package:rshd/features/auth/presentation/password_reset_controller.dart';
import 'package:rshd/features/auth/presentation/password_reset_verification_screen.dart';
import 'package:rshd/features/auth/presentation/widgets/otp_input_row.dart';
import 'package:rshd/features/auth/presentation/widgets/password_strength_indicator.dart';

class OfflineAuthRepository extends AuthRepository {
  OfflineAuthRepository()
    : super(
        apiClient: ApiClient(secureStorage: SecureStorageService()),
        secureStorage: SecureStorageService(),
        deviceService: DeviceService(secureStorage: SecureStorageService()),
      );

  @override
  Future<void> requestPasswordReset({required String email}) async {
    throw Exception('SocketException');
  }
}

void main() {
  group('ForgotPasswordScreen', () {
    testWidgets('shows validation for empty and invalid email', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إرسال رمز الاستعادة'));
      await tester.pumpAndSettle();
      expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.text('إرسال رمز الاستعادة'));
      await tester.pumpAndSettle();
      expect(find.text('صيغة البريد غير صحيحة'), findsOneWidget);
    });
  });

  group('PasswordResetVerificationScreen', () {
    testWidgets('renders otp row and verify action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PasswordResetVerificationScreen(
              email: 'student@rshdacademy.com',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OtpInputRow), findsOneWidget);
      expect(find.text('تحقق'), findsOneWidget);
      expect(find.textContaining('student@rshdacademy.com'), findsOneWidget);
    });
  });

  group('OtpInputRow', () {
    testWidgets('completes after entering six digits', (tester) async {
      String? completed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputRow(
              length: 6,
              onCompleted: (value) => completed = value,
            ),
          ),
        ),
      );

      final fields = find.byType(TextField);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '$i');
        await tester.pump();
      }

      expect(completed, '012345');
    });
  });

  group('PasswordStrengthIndicator', () {
    testWidgets('shows strength label for valid password', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(password: 'Strongpass1'),
          ),
        ),
      );

      expect(find.textContaining('قوة كلمة المرور'), findsOneWidget);
    });
  });

  group('PasswordResetController', () {
    test('maps offline errors to Arabic message', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(OfflineAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        passwordResetControllerProvider.notifier,
      );
      final success = await controller.requestReset('student@rshdacademy.com');

      expect(success, isFalse);
      expect(
        container.read(passwordResetControllerProvider).errorMessage,
        'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت.',
      );
    });
  });
}
