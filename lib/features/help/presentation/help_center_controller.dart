import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/help_center_model.dart';
import '../data/help_center_repository.dart';

class HelpCenterState {
  const HelpCenterState({
    this.status = FeatureLoadStatus.initial,
    this.contacts,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final HelpCenterContactsModel? contacts;
  final String? errorMessage;

  HelpCenterState copyWith({
    FeatureLoadStatus? status,
    HelpCenterContactsModel? contacts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HelpCenterState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class HelpCenterController extends StateNotifier<HelpCenterState> {
  HelpCenterController(this._repository) : super(const HelpCenterState());

  final HelpCenterRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && state.status == FeatureLoadStatus.loading) {
      return;
    }

    state = state.copyWith(
      status: refresh ? state.status : FeatureLoadStatus.loading,
      clearError: true,
    );

    try {
      final contacts = await _repository.getContacts();
      state = HelpCenterState(
        status: contacts.teachers.isEmpty && contacts.supportEmail.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        contacts: contacts,
      );
    } on ApiException catch (error) {
      state = HelpCenterState(
        status: FeatureLoadStatus.error,
        errorMessage: error.message.isNotEmpty
            ? error.message
            : 'تعذر تحميل مركز المساعدة',
      );
    } catch (_) {
      state = const HelpCenterState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر تحميل مركز المساعدة',
      );
    }
  }

  Future<void> sendMessage({
    required int subjectId,
    required String message,
  }) async {
    try {
      await _repository.sendMessage(subjectId: subjectId, message: message);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'تعذر إرسال الرسالة');
    }
  }
}

final helpCenterControllerProvider =
    StateNotifierProvider<HelpCenterController, HelpCenterState>((ref) {
      return HelpCenterController(ref.watch(helpCenterRepositoryProvider));
    });
