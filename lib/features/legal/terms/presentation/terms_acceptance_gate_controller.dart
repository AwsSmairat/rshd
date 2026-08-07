import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../data/terms_and_conditions_model.dart';
import '../data/terms_and_conditions_repository.dart';

class TermsAcceptanceGateState {
  const TermsAcceptanceGateState({
    this.isLoading = false,
    this.status,
    this.errorMessage,
  });

  final bool isLoading;
  final TermsAcceptanceStatus? status;
  final String? errorMessage;

  bool get requiresAcceptance => status?.requiresAcceptance ?? false;

  TermsAcceptanceGateState copyWith({
    bool? isLoading,
    TermsAcceptanceStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool clearStatus = false,
  }) {
    return TermsAcceptanceGateState(
      isLoading: isLoading ?? this.isLoading,
      status: clearStatus ? null : (status ?? this.status),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TermsAcceptanceGateController
    extends StateNotifier<TermsAcceptanceGateState> {
  TermsAcceptanceGateController(this._repository)
      : super(const TermsAcceptanceGateState());

  final TermsAndConditionsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final status = await _repository.fetchAcceptanceStatus();
      state = state.copyWith(isLoading: false, status: status);
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message.isNotEmpty
            ? error.message
            : 'تعذر التحقق من حالة الموافقة',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر التحقق من حالة الموافقة',
      );
    }
  }

  Future<bool> accept() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.acceptTerms();
      await refresh();
      return !state.requiresAcceptance;
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message.isNotEmpty
            ? error.message
            : 'تعذر تسجيل الموافقة',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تسجيل الموافقة',
      );
      return false;
    }
  }

  void reset() {
    state = const TermsAcceptanceGateState();
  }
}

final termsAcceptanceGateProvider = StateNotifierProvider<
    TermsAcceptanceGateController, TermsAcceptanceGateState>((ref) {
  final controller = TermsAcceptanceGateController(
    ref.watch(termsAndConditionsRepositoryProvider),
  );

  ref.listen(authControllerProvider, (previous, next) {
    if (next.status == AuthStatus.authenticated &&
        previous?.status != AuthStatus.authenticated) {
      controller.refresh();
    } else if (next.status == AuthStatus.unauthenticated) {
      controller.reset();
    }
  });

  if (ref.read(authControllerProvider).status == AuthStatus.authenticated) {
    Future.microtask(controller.refresh);
  }

  return controller;
});
