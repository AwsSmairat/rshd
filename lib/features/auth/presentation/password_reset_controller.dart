import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';

enum PasswordResetStatus { initial, loading, success, error }

class PasswordResetState {
  const PasswordResetState({
    this.status = PasswordResetStatus.initial,
    this.email,
    this.resetToken,
    this.errorMessage,
    this.fieldErrors = const {},
    this.successMessage,
  });

  final PasswordResetStatus status;
  final String? email;
  final String? resetToken;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final String? successMessage;

  bool get isLoading => status == PasswordResetStatus.loading;

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    String? email,
    String? resetToken,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      email: email ?? this.email,
      resetToken: resetToken ?? this.resetToken,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class PasswordResetController extends StateNotifier<PasswordResetState> {
  PasswordResetController(this._repository) : super(const PasswordResetState());

  final AuthRepository _repository;

  Future<bool> requestReset(String email) async {
    state = state.copyWith(
      status: PasswordResetStatus.loading,
      email: email.trim().toLowerCase(),
      clearError: true,
      clearSuccess: true,
      fieldErrors: {},
    );

    try {
      await _repository.requestPasswordReset(email: email);
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.success,
        successMessage:
            'إذا كان البريد مسجلاً لدينا، فستصلك رسالة تحتوي على رمز الاستعادة.',
      );
      return true;
    } on ApiException catch (error) {
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.error,
        errorMessage: _mapError(error),
        fieldErrors: _mapFieldErrors(error),
      );
      return false;
    } catch (_) {
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.error,
        errorMessage: 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت.',
      );
      return false;
    }
  }

  Future<bool> verifyCode({required String email, required String code}) async {
    state = state.copyWith(
      status: PasswordResetStatus.loading,
      email: email.trim().toLowerCase(),
      clearError: true,
      fieldErrors: {},
    );

    try {
      final resetToken = await _repository.verifyPasswordResetCode(
        email: email,
        code: code,
      );
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.success,
        resetToken: resetToken,
      );
      return true;
    } on ApiException catch (error) {
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.error,
        errorMessage: _mapError(error),
        fieldErrors: _mapFieldErrors(error),
      );
      return false;
    } catch (_) {
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.error,
        errorMessage: 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت.',
      );
      return false;
    }
  }

  Future<bool> resendCode(String email) async {
    try {
      await _repository.resendPasswordResetCode(email: email);
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        successMessage: 'تم إرسال رمز استعادة جديد.',
        clearError: true,
      );
      return true;
    } on ApiException catch (error) {
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(errorMessage: _mapError(error));
      return false;
    } catch (_) {
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        errorMessage: 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت.',
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(
      status: PasswordResetStatus.loading,
      clearError: true,
      fieldErrors: {},
    );

    try {
      await _repository.resetPassword(
        email: email,
        resetToken: resetToken,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.success,
        successMessage: 'تم تغيير كلمة المرور بنجاح.',
        resetToken: null,
      );
      return true;
    } on ApiException catch (error) {
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.error,
        errorMessage: _mapError(error),
        fieldErrors: _mapFieldErrors(error),
      );
      return false;
    } catch (_) {
      if (mounted == false) {
        return false;
      }

      state = state.copyWith(
        status: PasswordResetStatus.error,
        errorMessage: 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت.',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
      fieldErrors: {},
    );
  }

  String _mapError(ApiException error) {
    if (error.statusCode == null) {
      return 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت.';
    }
    if (error.statusCode == 429) {
      return error.message.isNotEmpty
          ? error.message
          : 'تم تجاوز عدد المحاولات. يرجى المحاولة لاحقاً.';
    }
    if (error.message.contains('غير صحيح')) {
      return 'الرمز غير صحيح';
    }
    if (error.message.contains('انتهت')) {
      return 'انتهت صلاحية الرمز';
    }
    if (error.message.contains('المحاولات')) {
      return 'تم تجاوز عدد المحاولات';
    }
    return error.message.isNotEmpty ? error.message : 'تعذر إكمال العملية.';
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

final passwordResetControllerProvider =
    StateNotifierProvider.autoDispose<
      PasswordResetController,
      PasswordResetState
    >((ref) => PasswordResetController(ref.watch(authRepositoryProvider)));
