import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../data/terms_and_conditions_model.dart';
import '../data/terms_and_conditions_repository.dart';

class TermsAndConditionsState {
  const TermsAndConditionsState({
    this.status = TermsLoadStatus.initial,
    this.document,
    this.errorMessage,
    this.isOfflineFallback = false,
    this.isAccepting = false,
    this.acceptanceMessage,
  });

  final TermsLoadStatus status;
  final TermsDocument? document;
  final String? errorMessage;
  final bool isOfflineFallback;
  final bool isAccepting;
  final String? acceptanceMessage;

  TermsAndConditionsState copyWith({
    TermsLoadStatus? status,
    TermsDocument? document,
    String? errorMessage,
    bool? isOfflineFallback,
    bool? isAccepting,
    String? acceptanceMessage,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return TermsAndConditionsState(
      status: status ?? this.status,
      document: document ?? this.document,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
      isAccepting: isAccepting ?? this.isAccepting,
      acceptanceMessage:
          clearMessage ? null : (acceptanceMessage ?? this.acceptanceMessage),
    );
  }
}

class TermsAndConditionsController
    extends StateNotifier<TermsAndConditionsState> {
  TermsAndConditionsController(this._repository)
      : super(const TermsAndConditionsState());

  final TermsAndConditionsRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && state.status == TermsLoadStatus.loading) {
      return;
    }

    state = state.copyWith(
      status: refresh ? state.status : TermsLoadStatus.loading,
      clearError: true,
      clearMessage: true,
    );

    try {
      final document = await _repository.fetch(forceRefresh: refresh);
      final isOffline = document.source == TermsSource.local ||
          document.source == TermsSource.cached;

      state = state.copyWith(
        status: TermsLoadStatus.loaded,
        document: document,
        isOfflineFallback: isOffline,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        status: TermsLoadStatus.error,
        errorMessage: error.message.isNotEmpty
            ? error.message
            : 'تعذر تحميل الشروط والأحكام',
      );
    } catch (_) {
      state = state.copyWith(
        status: TermsLoadStatus.error,
        errorMessage: 'تعذر تحميل الشروط والأحكام',
      );
    }
  }

  Future<bool> acceptTerms() async {
    if (state.isAccepting) {
      return false;
    }

    state = state.copyWith(isAccepting: true, clearError: true, clearMessage: true);

    try {
      await _repository.acceptTerms();
      await load(refresh: true);
      state = state.copyWith(
        isAccepting: false,
        acceptanceMessage: 'تم تسجيل موافقتك على الشروط',
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(
        isAccepting: false,
        errorMessage: error.message.isNotEmpty
            ? error.message
            : 'تعذر تسجيل الموافقة',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isAccepting: false,
        errorMessage: 'تعذر تسجيل الموافقة',
      );
      return false;
    }
  }
}

final termsAndConditionsControllerProvider = StateNotifierProvider<
    TermsAndConditionsController, TermsAndConditionsState>((ref) {
  return TermsAndConditionsController(
    ref.watch(termsAndConditionsRepositoryProvider),
  );
});
