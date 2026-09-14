import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/announcements_repository.dart';
import '../data/models/announcement_model.dart';

class AnnouncementsListState {
  const AnnouncementsListState({
    this.status = FeatureLoadStatus.initial,
    this.announcements = const [],
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final List<AnnouncementModel> announcements;
  final String? errorMessage;

  AnnouncementsListState copyWith({
    FeatureLoadStatus? status,
    List<AnnouncementModel>? announcements,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnnouncementsListState(
      status: status ?? this.status,
      announcements: announcements ?? this.announcements,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AnnouncementDetailsState {
  const AnnouncementDetailsState({
    this.status = FeatureLoadStatus.initial,
    this.announcement,
    this.errorMessage,
  });

  final FeatureLoadStatus status;
  final AnnouncementModel? announcement;
  final String? errorMessage;

  AnnouncementDetailsState copyWith({
    FeatureLoadStatus? status,
    AnnouncementModel? announcement,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnnouncementDetailsState(
      status: status ?? this.status,
      announcement: announcement ?? this.announcement,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

String mapAnnouncementsError(ApiException error) {
  if (error.isForbidden) {
    return 'لا تملك صلاحية الوصول إلى هذا الإعلان';
  }
  if (error.isUnauthorized) {
    return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message.isNotEmpty ? error.message : 'تعذر تحميل الإعلانات';
}

class AnnouncementsListController
    extends StateNotifier<AnnouncementsListState> {
  AnnouncementsListController(this._repository)
    : super(const AnnouncementsListState());

  final AnnouncementsRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (state.status == FeatureLoadStatus.loading && !refresh) {
      return;
    }

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final announcements = await _repository.getAnnouncements();

      if (!mounted) {
        return;
      }

      state = AnnouncementsListState(
        status: announcements.isEmpty
            ? FeatureLoadStatus.empty
            : FeatureLoadStatus.loaded,
        announcements: announcements,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      state = AnnouncementsListState(
        status: FeatureLoadStatus.error,
        errorMessage: mapAnnouncementsError(error),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      state = const AnnouncementsListState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }

  AnnouncementModel? findById(int id) {
    for (final announcement in state.announcements) {
      if (announcement.id == id) {
        return announcement;
      }
    }
    return null;
  }
}

class AnnouncementDetailsController
    extends StateNotifier<AnnouncementDetailsState> {
  AnnouncementDetailsController(this._repository)
    : super(const AnnouncementDetailsState());

  final AnnouncementsRepository _repository;

  void setAnnouncement(AnnouncementModel announcement) {
    state = AnnouncementDetailsState(
      status: FeatureLoadStatus.loaded,
      announcement: announcement,
    );
  }

  Future<void> load(int announcementId, {AnnouncementModel? cached}) async {
    if (cached != null) {
      state = AnnouncementDetailsState(
        status: FeatureLoadStatus.loaded,
        announcement: cached,
      );
      return;
    }

    state = state.copyWith(status: FeatureLoadStatus.loading, clearError: true);

    try {
      final announcement = await _repository.findById(announcementId);
      if (mounted == false) {
        return;
      }

      if (announcement == null) {
        state = const AnnouncementDetailsState(
          status: FeatureLoadStatus.error,
          errorMessage: 'الإعلان غير موجود',
        );
        return;
      }

      state = AnnouncementDetailsState(
        status: FeatureLoadStatus.loaded,
        announcement: announcement,
      );
    } on ApiException catch (error) {
      if (mounted == false) {
        return;
      }

      state = AnnouncementDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: mapAnnouncementsError(error),
      );
    } catch (_) {
      if (mounted == false) {
        return;
      }

      state = const AnnouncementDetailsState(
        status: FeatureLoadStatus.error,
        errorMessage: 'تعذر الاتصال بالسيرفر',
      );
    }
  }
}

final announcementsListControllerProvider =
    StateNotifierProvider<AnnouncementsListController, AnnouncementsListState>((
      ref,
    ) {
      return AnnouncementsListController(
        ref.watch(announcementsRepositoryProvider),
      );
    });

final announcementDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<AnnouncementDetailsController, AnnouncementDetailsState, int>((
      ref,
      announcementId,
    ) {
      return AnnouncementDetailsController(
        ref.watch(announcementsRepositoryProvider),
      );
    });
