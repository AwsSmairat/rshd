import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/models/profile_model.dart';
import '../data/profile_repository.dart';

class ProfileState {
  const ProfileState({
    this.status = FeatureLoadStatus.initial,
    this.profile,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final ProfileModel? profile;
  final String? errorMessage;

  ProfileState copyWith({
    FeatureLoadStatus? status,
    ProfileModel? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

String mapProfileError(ApiException error) {
  if (error.isUnauthorized) {
    return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message.isNotEmpty
      ? error.message
      : 'تعذر تحميل الملف الشخصي';
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(
      status: FeatureLoadStatus.loading,
      clearError: true,
    );

    try {
      final profile = await _repository.getProfile();
      state = ProfileState(
        status: FeatureLoadStatus.loaded,
        profile: profile,
      );
    } on ApiException catch (error) {
      state = ProfileState(
        status: FeatureLoadStatus.error,
        errorMessage: mapProfileError(error),
      );
    } catch (_) {
      state = const ProfileState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref.watch(profileRepositoryProvider));
});
