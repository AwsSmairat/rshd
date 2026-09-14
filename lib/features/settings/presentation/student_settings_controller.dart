import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/models/student_settings_model.dart';
import '../data/settings_repository.dart';
import '../data/student_avatar_store.dart';

class StudentSettingsState {
  const StudentSettingsState({
    this.status = FeatureLoadStatus.initial,
    this.settings,
    this.errorMessage,
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.actionMessage,
    this.localAvatarPath,
  });

  final FeatureLoadStatus status;
  final StudentSettingsModel? settings;
  final String? errorMessage;
  final bool isSaving;
  final bool isUploadingAvatar;
  final String? actionMessage;
  final String? localAvatarPath;

  StudentSettingsState copyWith({
    FeatureLoadStatus? status,
    StudentSettingsModel? settings,
    String? errorMessage,
    bool? isSaving,
    bool? isUploadingAvatar,
    String? actionMessage,
    String? localAvatarPath,
    bool clearError = false,
    bool clearMessage = false,
    bool clearLocalAvatar = false,
  }) {
    return StudentSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSaving: isSaving ?? this.isSaving,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      actionMessage: clearMessage
          ? null
          : (actionMessage ?? this.actionMessage),
      localAvatarPath: clearLocalAvatar
          ? null
          : (localAvatarPath ?? this.localAvatarPath),
    );
  }
}

String mapSettingsError(ApiException error) {
  if (error.isUnauthorized) {
    return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
  }
  if (error.statusCode == null && error.message.contains('اتصال')) {
    return 'تعذر الاتصال بالسيرفر';
  }
  return error.message.isNotEmpty ? error.message : 'حدث خطأ غير متوقع';
}

class StudentSettingsController extends StateNotifier<StudentSettingsState> {
  StudentSettingsController(this._repository, {StudentAvatarStore? avatarStore})
    : _avatarStore = avatarStore ?? StudentAvatarStore(),
      super(const StudentSettingsState());

  final SettingsRepository _repository;
  final StudentAvatarStore _avatarStore;

  Future<String?> _resolveLocalAvatar(StudentSettingsModel settings) async {
    final remoteUrl = settings.profile.avatarUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      await _avatarStore.clear();
      return null;
    }

    final cached = await _avatarStore.existingPath();

    if (!mounted) {
      return null;
    }

    if (cached != null) {
      return cached;
    }

    final bytes = await _repository.downloadAvatar();

    if (!mounted) {
      return null;
    }

    if (bytes != null) {
      try {
        final saved = await _avatarStore.saveFromBytes(bytes);

        if (!mounted) {
          return null;
        }

        return saved;
      } catch (_) {
        if (!mounted) {
          return null;
        }

        return state.localAvatarPath;
      }
    }

    // Keep a just-picked preview if a background settings reload races us.
    return state.localAvatarPath;
  }

  Future<void> load({bool refresh = false}) async {
    if (!refresh && state.status == FeatureLoadStatus.loading) {
      return;
    }

    state = state.copyWith(
      status: refresh ? state.status : FeatureLoadStatus.loading,
      clearError: true,
      clearMessage: true,
    );

    try {
      final settings = await _repository.getSettings();

      if (!mounted) {
        return;
      }

      final localPath = await _resolveLocalAvatar(settings);

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: FeatureLoadStatus.loaded,
        settings: settings,
        localAvatarPath: localPath,
        clearLocalAvatar: localPath == null,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: FeatureLoadStatus.error,
        errorMessage: mapSettingsError(error),
      );
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? birthDate,
    String? gender,
    String? country,
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearMessage: true,
    );
    try {
      final settings = await _repository.updateProfile(
        name: name,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        country: country,
      );

      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        settings: settings,
        actionMessage: 'تم حفظ المعلومات الشخصية',
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        errorMessage: mapSettingsError(error),
      );
      return false;
    }
  }

  Future<bool> uploadAvatar(String path) async {
    String? previewPath = path;
    try {
      previewPath = await _avatarStore.saveFromPath(path);
    } catch (_) {
      previewPath = path;
    }

    if (!mounted) {
      return false;
    }

    state = state.copyWith(
      isUploadingAvatar: true,
      localAvatarPath: previewPath,
      clearError: true,
      clearMessage: true,
    );
    try {
      final settings = await _repository.uploadAvatar(path);

      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isUploadingAvatar: false,
        settings: settings,
        localAvatarPath: previewPath,
        actionMessage: 'تم تحديث الصورة الشخصية',
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: mapSettingsError(error),
      );
      return false;
    }
  }

  Future<bool> deleteAvatar() async {
    state = state.copyWith(isUploadingAvatar: true, clearMessage: true);
    try {
      final settings = await _repository.deleteAvatar();

      if (!mounted) {
        return false;
      }

      await _avatarStore.clear();

      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isUploadingAvatar: false,
        settings: settings,
        clearLocalAvatar: true,
        actionMessage: 'تم حذف الصورة الشخصية',
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: mapSettingsError(error),
      );
      return false;
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String password,
    required String confirmation,
  }) async {
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      await _repository.updatePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: confirmation,
      );

      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        actionMessage: 'تم تغيير كلمة المرور',
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        errorMessage: mapSettingsError(error),
      );
      return false;
    }
  }

  Future<void> updatePreferencesBatch(Map<String, dynamic> patch) async {
    final current = state.settings;
    if (current == null || patch.isEmpty) {
      return;
    }

    final previous = current.preferences;
    var optimistic = previous;
    patch.forEach((key, value) {
      optimistic = _applyPreferencePatch(optimistic, {key: value});
    });

    state = state.copyWith(
      settings: current.copyWith(preferences: optimistic),
      isSaving: true,
      clearError: true,
    );

    try {
      final settings = await _repository.updatePreferences(patch);

      if (!mounted) {
        return;
      }

      state = state.copyWith(settings: settings, isSaving: false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        settings: current.copyWith(preferences: previous),
        isSaving: false,
        errorMessage: mapSettingsError(error),
      );
    }
  }

  Future<void> updatePreference(String key, dynamic value) async {
    final current = state.settings;
    if (current == null) {
      return;
    }

    final previous = current.preferences;
    final optimistic = _applyPreferencePatch(previous, {key: value});

    state = state.copyWith(
      settings: current.copyWith(preferences: optimistic),
      isSaving: true,
    );

    try {
      final settings = await _repository.updatePreferences({key: value});

      if (!mounted) {
        return;
      }

      state = state.copyWith(settings: settings, isSaving: false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        settings: current.copyWith(preferences: previous),
        isSaving: false,
        errorMessage: mapSettingsError(error),
      );
    }
  }

  Future<bool> revokeDevice(int deviceId) async {
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      final settings = await _repository.revokeDevice(deviceId);

      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        settings: settings,
        actionMessage: 'تم تسجيل الخروج من الجهاز',
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        errorMessage: mapSettingsError(error),
      );
      return false;
    }
  }

  Future<bool> logoutAllDevices() async {
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      await _repository.logoutAllDevices();

      if (!mounted) {
        return false;
      }

      await load(refresh: true);

      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        actionMessage: 'تم تسجيل الخروج من الأجهزة الأخرى',
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        errorMessage: mapSettingsError(error),
      );
      return false;
    }
  }

  Future<bool> deleteAccount(String password) async {
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      await _repository.deleteAccount(password: password);

      if (!mounted) {
        return false;
      }

      state = state.copyWith(isSaving: false);
      return true;
    } on ApiException catch (error) {
      if (!mounted) {
        return false;
      }

      state = state.copyWith(
        isSaving: false,
        errorMessage: mapSettingsError(error),
      );
      return false;
    }
  }

  StudentPreferencesModel _applyPreferencePatch(
    StudentPreferencesModel prefs,
    Map<String, dynamic> patch,
  ) {
    var next = prefs;
    patch.forEach((key, value) {
      next = switch (key) {
        'notify_lessons' => next.copyWith(notifyLessons: value as bool),
        'notify_assignments' => next.copyWith(notifyAssignments: value as bool),
        'notify_assignment_reminders' => next.copyWith(
          notifyAssignmentReminders: value as bool,
        ),
        'notify_quizzes' => next.copyWith(notifyQuizzes: value as bool),
        'notify_quiz_reminders' => next.copyWith(
          notifyQuizReminders: value as bool,
        ),
        'notify_grades' => next.copyWith(notifyGrades: value as bool),
        'notify_messages' => next.copyWith(notifyMessages: value as bool),
        'notify_announcements' => next.copyWith(
          notifyAnnouncements: value as bool,
        ),
        'notify_platform_updates' => next.copyWith(
          notifyPlatformUpdates: value as bool,
        ),
        'notification_sound' => next.copyWith(notificationSound: value as bool),
        'notification_vibration' => next.copyWith(
          notificationVibration: value as bool,
        ),
        'language' => next.copyWith(language: value as String),
        'theme' => next.copyWith(theme: value as String),
        'font_size' => next.copyWith(fontSize: value as String),
        'downloads_wifi_only' => next.copyWith(
          downloadsWifiOnly: value as bool,
        ),
        'auto_play_video' => next.copyWith(autoPlayVideo: value as bool),
        'default_video_quality' => next.copyWith(
          defaultVideoQuality: value as String,
        ),
        'save_watch_position' => next.copyWith(
          saveWatchPosition: value as bool,
        ),
        'timezone' => next.copyWith(timezone: value as String),
        'profile_visibility' => next.copyWith(
          profileVisibility: value as String,
        ),
        'messaging_permission' => next.copyWith(
          messagingPermission: value as String,
        ),
        'show_activity_status' => next.copyWith(
          showActivityStatus: value as bool,
        ),
        'allow_profile_photo_use' => next.copyWith(
          allowProfilePhotoUse: value as bool,
        ),
        'two_factor_enabled' => next.copyWith(twoFactorEnabled: value as bool),
        _ => next,
      };
    });
    return next;
  }
}

final studentSettingsControllerProvider =
    StateNotifierProvider<StudentSettingsController, StudentSettingsState>((
      ref,
    ) {
      return StudentSettingsController(ref.watch(settingsRepositoryProvider));
    });
