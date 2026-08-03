import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';

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

  Future<bool> _rejectNonStudentAccess({required AuthStatus status}) async {
    await _repository.logout();
    state = AuthState(
      status: status,
      errorMessage: studentOnlyMessage,
    );
    return false;
  }

  Future<void> bootstrap() async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      fieldErrors: {},
      clearPendingVerificationEmail: true,
    );

    final hasToken = await _repository.hasToken();
    if (!hasToken) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearError: true,
      );
      return;
    }

    final cachedEmail = (await _repository.getCachedUser())?.email;

    try {
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
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } on ApiException catch (error) {
      await _repository.logout();
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
      await _repository.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
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

      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      );
      return LoginFlowResult.success;
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapLoginError(error),
        fieldErrors: _mapFieldErrors(error),
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

      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      );
      return RegisterResult.authenticated;
    } on ApiException catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: error.message,
        fieldErrors: _mapFieldErrors(error),
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

      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      );
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
    if (error.isForbidden) {
      if (error.message.contains('جهاز آخر')) {
        return error.message;
      }
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

  String _mapVerificationError(ApiException error) {
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
    return error.message.isNotEmpty ? error.message : 'تعذر تأكيد البريد الإلكتروني';
  }

  Map<String, String> _mapFieldErrors(ApiException error) {
    final mapped = <String, String>{};
    error.errors?.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        mapped[key] = value.first.toString();
      } else if (value != null) {
        mapped[key] = value.toString();
      }
    });
    return mapped;
  }
}

enum LoginFlowResult {
  success,
  requiresEmailVerification,
  cancelled,
  failed,
}

enum RegisterResult {
  requiresEmailVerification,
  authenticated,
  failed,
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
