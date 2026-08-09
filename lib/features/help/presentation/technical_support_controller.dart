import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/technical_support_model.dart';
import '../data/technical_support_repository.dart';

class TechnicalSupportState {
  const TechnicalSupportState({
    this.status = FeatureLoadStatus.initial,
    this.conversation,
    this.errorMessage,
    this.sending = false,
  });

  final FeatureLoadStatus status;
  final SupportConversationModel? conversation;
  final String? errorMessage;
  final bool sending;

  TechnicalSupportState copyWith({
    FeatureLoadStatus? status,
    SupportConversationModel? conversation,
    String? errorMessage,
    bool? sending,
    bool clearError = false,
  }) {
    return TechnicalSupportState(
      status: status ?? this.status,
      conversation: conversation ?? this.conversation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sending: sending ?? this.sending,
    );
  }
}

class TechnicalSupportController extends StateNotifier<TechnicalSupportState> {
  TechnicalSupportController(this._repository)
    : super(const TechnicalSupportState());

  final TechnicalSupportRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && state.status == FeatureLoadStatus.loading) {
      return;
    }

    state = state.copyWith(
      status: refresh ? state.status : FeatureLoadStatus.loading,
      clearError: true,
    );

    try {
      final conversation = await _repository.getConversation();
      state = TechnicalSupportState(
        status: FeatureLoadStatus.loaded,
        conversation: conversation,
      );
    } on ApiException catch (error) {
      state = TechnicalSupportState(
        status: FeatureLoadStatus.error,
        errorMessage: error.message.isNotEmpty
            ? error.message
            : 'تعذر تحميل محادثة الدعم',
      );
    } catch (_) {
      state = const TechnicalSupportState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر تحميل محادثة الدعم',
      );
    }
  }

  Future<void> sendMessage(String message) async {
    state = state.copyWith(sending: true, clearError: true);

    try {
      final conversation = await _repository.sendMessage(message);
      state = TechnicalSupportState(
        status: FeatureLoadStatus.loaded,
        conversation: conversation,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        sending: false,
        errorMessage: error.message.isNotEmpty
            ? error.message
            : 'تعذر إرسال الرسالة',
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(
        sending: false,
        errorMessage: 'تعذر إرسال الرسالة',
      );
      rethrow;
    }
  }
}

final technicalSupportControllerProvider =
    StateNotifierProvider<TechnicalSupportController, TechnicalSupportState>((
      ref,
    ) {
      return TechnicalSupportController(
        ref.watch(technicalSupportRepositoryProvider),
      );
    });
