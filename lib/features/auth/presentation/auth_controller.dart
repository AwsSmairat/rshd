import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/session_invalidation.dart';
import '../../../core/security/protected_content_cache.dart';
import '../../../core/startup/startup_timing.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';

const _deviceMismatchMessage =
    'هذا الحساب متصل على جهاز آخر، يرجى التواصل مع الإدارة لإعادة تعيين الجهاز.';

enum AuthStatus {
  initial,
  loading,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.fieldErrors = const {},
    this.pendingVerificationEmail,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final String? pendingVerificationEmail;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    String? pendingVerificationEmail,
    bool clearUser = false,
    bool clearError = false,
    bool clearPendingVerificationEmail = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      pendingVerificationEmail: clearPendingVerificationEmail
          ? null
          : (pendingVerificationEmail ?? this.pendingVerificationEmail),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  static const studentOnlyMessage =
      'هذا التطبيق مخصص للطلاب فقط. يرجى استخدام لوحة التحكم من المتصفح.';

  final AuthRepository _repository;
  bool _bootstrapInFlight = false;
  bool _bootstrapCompleted = false;

  Future<bool> _rejectNonStudentAccess({required AuthStatus status}) async {
    await _repository.logout();
    state = AuthState(status: status, errorMessage: studentOnlyMessage);
    return false;
  }

  Future<void> bootstrap() async {
    if (_bootstrapCompleted || _bootstrapInFlight) {
      return;
    }
    _bootstrapInFlight = true;

    StartupTiming.mark('T3');
    try {
      final results = await Future.wait<Object?>([
        _repository.purgeLegacyRememberedPassword(),
        _repository.hasToken(),
      ]);
      StartupTiming.mark('T4');

      final hasToken = results[1] as bool;

      state = state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
        fieldErrors: {},
        clearPendingVerificationEmail: true,
      );

      if (!hasToken) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        );
        return;
      }

      String? cachedEmail;

      try {
        cachedEmail = (await _repository.getCachedUser())?.email;

        final user = await _repository.me();
        if (!user.isStudent) {
          await _rejectNonStudentAccess(status: AuthStatus.unauthenticated);
          return;
        }
        if (!user.isEmailVerified) {
          await _repository.logout();
          state = AuthState(
            status: AuthStatus.unauthenticated,
            pendingVerificationEmail: user.email,
            errorMessage: 'يرجى تأكيد بريدك الإلكتروني قبل استخدام التطبيق.',
          );
          return;
        }
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } on ApiException catch (error) {
        // Only authentication/authorization rejection proves that the stored
        // session must be discarded. Transient network/server failures must
        // not erase an otherwise valid local session.
        if (error.isUnauthorized || error.isForbidden) {
          await invalidateSession();
        }

        if (error.message.contains('تأكيد بريدك')) {
          state = AuthState(
            status: AuthStatus.unauthenticated,
            pendingVerificationEmail: cachedEmail,
            errorMessage: error.message,
          );
          return;
        }

        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: error.isUnauthorized ? null : error.message,
        );
      } catch (_) {
        // Fail closed, but do not destroy the stored session for an
        // unexpected/transient bootstrap failure.
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'تعذر الاتصال بالسيرفر',
        );
      }
    } finally {
      _bootstrapInFlight = false;
      _bootstrapCompleted = true;
    }
  }

  Future<LoginFlowResult> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      fieldErrors: {},
      clearPendingVerificationEmail: true,
    );

    try {
      final outcome = await _repository.login(
        email: email.trim(),
        password: password,
      );

      if (outcome.requiresEmailVerification) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          pendingVerificationEmail: outcome.verificationEmail,
          errorMessage: 'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.',
        );
        return LoginFlowResult.requiresEmailVerification;
      }

      final session = outcome.session!;
      if (!session.user.isStudent) {
        await _rejectNonStudentAccess(status: AuthStatus.error);
        return LoginFlowResult.failed;
      }
      if (!session.user.isEmailVerified) {
        await _repository.logout();
        state = AuthState(
          status: AuthStatus.unauthenticated,
          pendingVerificationEmail: session.user.email,
          errorMessage: 'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.',
        );
        return LoginFlowResult.requiresEmailVerification;
      }

      final previousUserId = state.user?.id;

      state = AuthState(status: AuthStatus.authenticated, user: session.user);

      await ProtectedContentCache.onUserChanged(
        previousUserId: previousUserId,
        nextUserId: session.user.id,
      );

      return LoginFlowResult.success;
    } on ApiException catch (error) {
      final isDeviceMismatch = _isDeviceMismatchError(error);
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: isDeviceMismatch
            ? _deviceMismatchMessage
            : _mapLoginError(error),
        fieldErrors: isDeviceMismatch ? const {} : _mapFieldErrors(error),
      );
      return LoginFlowResult.failed;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'خطأ غير متوقع. يرجى المحاولة لاحقاً.',
      );
      return LoginFlowResult.failed;
    }
  }

  Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      fieldErrors: {},
      clearPendingVerificationEmail: true,
    );

    try {
      final outcome = await _repository.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone?.trim().isEmpty ?? true ? null : phone?.trim(),
      );

      if (outcome.requiresEmailVerification) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          pendingVerificationEmail: outcome.verificationEmail,
        );
        return RegisterResult.requiresEmailVerification;
      }

      final session = outcome.session!;
      if (!session.user.isStudent) {
        await _rejectNonStudentAccess(status: AuthStatus.error);
        return RegisterResult.failed;
      }

      state = AuthState(status: AuthStatus.authenticated, user: session.user);
      return RegisterResult.authenticated;
    } on ApiException catch (error) {
      final isDeviceMismatch = _isDeviceMismatchError(error);
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: isDeviceMismatch ? _deviceMismatchMessage : error.message,
        fieldErrors: isDeviceMismatch ? const {} : _mapFieldErrors(error),
      );
      return RegisterResult.failed;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'خطأ غير متوقع. يرجى المحاولة لاحقاً.',
      );
      return RegisterResult.failed;
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
      fieldErrors: {},
    );

    try {
      final session = await _repository.verifyEmail(
        email: email.trim(),
        code: code.trim(),
      );

      if (!session.user.isStudent) {
        await _rejectNonStudentAccess(status: AuthStatus.error);
        return false;
      }

      state = AuthState(status: AuthStatus.authenticated, user: session.user);
      return true;
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapVerificationError(error),
        pendingVerificationEmail: email.trim(),
      );
      return false;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
        pendingVerificationEmail: email.trim(),
      );
      return false;
    }
  }

  Future<bool> resendVerificationCode({required String email}) async {
    try {
      await _repository.resendVerificationCode(email: email.trim());
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(errorMessage: _mapVerificationError(error));
      return false;
    } catch (_) {
      state = state.copyWith(errorMessage: 'تعذر الاتصال بالسيرفر');
      return false;
    }
  }

  bool _isInvalidatingSession = false;

  Future<void> invalidateSession() async {
    if (_isInvalidatingSession || state.status == AuthStatus.unauthenticated) {
      return;
    }

    _isInvalidatingSession = true;

    // Fail closed immediately so protected UI is removed before any
    // feature-level error handler can keep using an invalid session.
    state = const AuthState(status: AuthStatus.unauthenticated);

    try {
      await _repository.clearLocalSession();
    } catch (_) {
      // The auth state must remain unauthenticated even if local cleanup
      // encounters an unexpected platform/storage error.
    } finally {
      _isInvalidatingSession = false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
        fieldErrors: {},
      );
    }
  }

  String _mapLoginError(ApiException error) {
    if (_isDeviceMismatchError(error)) {
      return _deviceMismatchMessage;
    }

    if (error.isForbidden) {
      if (error.message.contains('تأكيد بريدك')) {
        return error.message;
      }
      return error.message.contains('كلمة المرور')
          ? error.message
          : 'غير مصرح لك بالوصول.';
    }

    final emailError = error.firstFieldError('email');
    if (emailError != null) {
      if (emailError.contains('blocked')) {
        return 'الحساب موقوف.';
      }
      if (emailError.contains('incorrect')) {
        return 'بيانات الدخول غير صحيحة.';
      }
      return emailError;
    }

    return error.message;
  }

  bool _isDeviceMismatchError(ApiException error) {
    if (error.isDeviceMismatch) {
      return true;
    }

    final message = error.message;
    return message.contains('جهاز آخر') ||
        message.contains('device_mismatch') ||
        (error.isForbidden &&
            (message.contains('متصل') || message.contains('مرتبط')));
  }

  String _mapVerificationError(ApiException error) {
    if (_isDeviceMismatchError(error)) {
      return _deviceMismatchMessage;
    }

    if (error.statusCode == null && error.message.contains('اتصال')) {
      return 'تعذر الاتصال بالسيرفر';
    }
    if (error.message.contains('غير صحيح')) {
      return 'الرمز غير صحيح';
    }
    if (error.message.contains('انتهت صلاحية')) {
      return 'انتهت صلاحية الرمز';
    }
    if (error.message.contains('المحاولات')) {
      return 'تم تجاوز عدد المحاولات';
    }
    if (error.message.contains('60 ثانية')) {
      return error.message;
    }
    return error.message.isNotEmpty
        ? error.message
        : 'تعذر تأكيد البريد الإلكتروني';
  }

  Map<String, String> _mapFieldErrors(ApiException error) {
    if (_isDeviceMismatchError(error)) {
      return const {};
    }

    final mapped = <String, String>{};
    error.errors?.forEach((key, value) {
      final raw = value is List && value.isNotEmpty
          ? value.first.toString()
          : value?.toString();
      if (raw == null || raw.isEmpty) {
        return;
      }

      if (key == 'email' && raw.contains('incorrect')) {
        mapped[key] = 'بيانات الدخول غير صحيحة.';
        return;
      }

      mapped[key] = raw;
    });
    return mapped;
  }
}

enum LoginFlowResult { success, requiresEmailVerification, failed }

enum RegisterResult { requiresEmailVerification, authenticated, failed }

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final controller = AuthController(ref.watch(authRepositoryProvider));

    ref.listen<int>(sessionInvalidationProvider, (previous, next) {
      unawaited(controller.invalidateSession());
    });

    return controller;
  },
);
