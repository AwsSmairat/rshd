import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../data/privacy_policy_model.dart';
import '../data/privacy_policy_repository.dart';

class PrivacyPolicyState {
  const PrivacyPolicyState({
    this.status = PrivacyPolicyLoadStatus.initial,
    this.document,
    this.errorMessage,
    this.isOfflineFallback = false,
  });

  final PrivacyPolicyLoadStatus status;
  final PrivacyPolicyDocument? document;
  final String? errorMessage;
  final bool isOfflineFallback;

  PrivacyPolicyState copyWith({
    PrivacyPolicyLoadStatus? status,
    PrivacyPolicyDocument? document,
    String? errorMessage,
    bool? isOfflineFallback,
    bool clearError = false,
  }) {
    return PrivacyPolicyState(
      status: status ?? this.status,
      document: document ?? this.document,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
    );
  }
}

class PrivacyPolicyController extends StateNotifier<PrivacyPolicyState> {
  PrivacyPolicyController(this._repository) : super(const PrivacyPolicyState());

  final PrivacyPolicyRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && state.status == PrivacyPolicyLoadStatus.loading) {
      return;
    }

    state = state.copyWith(
      status: refresh ? state.status : PrivacyPolicyLoadStatus.loading,
      clearError: true,
    );

    try {
      final document = await _repository.fetch(forceRefresh: refresh);
      final isOffline = document.source != PrivacyPolicySource.remote;

      state = state.copyWith(
        status: PrivacyPolicyLoadStatus.loaded,
        document: document,
        isOfflineFallback: isOffline && refresh,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        status: PrivacyPolicyLoadStatus.error,
        errorMessage: error.message.isNotEmpty
            ? error.message
            : 'تعذر تحميل سياسة الخصوصية',
      );
    } catch (_) {
      state = state.copyWith(
        status: PrivacyPolicyLoadStatus.error,
        errorMessage: 'تعذر تحميل سياسة الخصوصية',
      );
    }
  }
}

final privacyPolicyControllerProvider =
    StateNotifierProvider<PrivacyPolicyController, PrivacyPolicyState>((ref) {
      return PrivacyPolicyController(
        ref.watch(privacyPolicyRepositoryProvider),
      );
    });
