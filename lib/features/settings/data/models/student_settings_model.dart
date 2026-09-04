import '../../../profile/data/models/device_model.dart';

class StudentSettingsModel {
  const StudentSettingsModel({
    required this.profile,
    required this.preferences,
    required this.devices,
  });

  final StudentProfileModel profile;
  final StudentPreferencesModel preferences;
  final List<DeviceModel> devices;

  factory StudentSettingsModel.fromJson(Map<String, dynamic> json) {
    return StudentSettingsModel(
      profile: StudentProfileModel.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? {}),
      ),
      preferences: StudentPreferencesModel.fromJson(
        Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
      ),
      devices: (json['devices'] as List? ?? [])
          .whereType<Map>()
          .map((item) => DeviceModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  StudentSettingsModel copyWith({
    StudentProfileModel? profile,
    StudentPreferencesModel? preferences,
    List<DeviceModel>? devices,
  }) {
    return StudentSettingsModel(
      profile: profile ?? this.profile,
      preferences: preferences ?? this.preferences,
      devices: devices ?? this.devices,
    );
  }
}

class StudentProfileModel {
  const StudentProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.gender,
    this.country,
    this.studentNumber,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.passwordSetAt,
    this.createdAt,
    this.activeDevice,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? birthDate;
  final String? gender;
  final String? country;
  final String? studentNumber;
  final String role;
  final String status;
  final String? avatarUrl;
  final String? passwordSetAt;
  final String? createdAt;
  final DeviceModel? activeDevice;

  String get roleLabel => role == 'student' ? 'طالب' : role;

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'blocked':
        return 'موقوف';
      default:
        return status;
    }
  }

  String get genderLabel {
    switch (gender) {
      case 'male':
        return 'ذكر';
      case 'female':
        return 'أنثى';
      default:
        return '—';
    }
  }

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    DeviceModel? activeDevice;
    final deviceJson = json['active_device'];
    if (deviceJson is Map) {
      try {
        activeDevice = DeviceModel.fromJson(
          Map<String, dynamic>.from(deviceJson),
        );
      } catch (_) {
        activeDevice = null;
      }
    }

    return StudentProfileModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      birthDate: json['birth_date']?.toString(),
      gender: json['gender']?.toString(),
      country: json['country']?.toString(),
      studentNumber: json['student_number']?.toString(),
      role: json['role']?.toString() ?? 'student',
      status: json['status']?.toString() ?? 'active',
      avatarUrl: json['avatar_url']?.toString(),
      passwordSetAt: json['password_set_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      activeDevice: activeDevice,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}

class StudentPreferencesModel {
  const StudentPreferencesModel({
    this.notifyLessons = true,
    this.notifyAssignments = true,
    this.notifyAssignmentReminders = true,
    this.notifyQuizzes = true,
    this.notifyQuizReminders = true,
    this.notifyGrades = true,
    this.notifyMessages = true,
    this.notifyAnnouncements = true,
    this.notifyPlatformUpdates = true,
    this.notificationSound = true,
    this.notificationVibration = true,
    this.language = 'ar',
    this.theme = 'light',
    this.fontSize = 'medium',
    this.downloadsWifiOnly = true,
    this.autoPlayVideo = false,
    this.defaultVideoQuality = 'auto',
    this.saveWatchPosition = true,
    this.timezone = 'Asia/Amman',
    this.profileVisibility = 'teachers_only',
    this.messagingPermission = 'teachers_only',
    this.showActivityStatus = true,
    this.allowProfilePhotoUse = true,
    this.twoFactorEnabled = false,
  });

  final bool notifyLessons;
  final bool notifyAssignments;
  final bool notifyAssignmentReminders;
  final bool notifyQuizzes;
  final bool notifyQuizReminders;
  final bool notifyGrades;
  final bool notifyMessages;
  final bool notifyAnnouncements;
  final bool notifyPlatformUpdates;
  final bool notificationSound;
  final bool notificationVibration;
  final String language;
  final String theme;
  final String fontSize;
  final bool downloadsWifiOnly;
  final bool autoPlayVideo;
  final String defaultVideoQuality;
  final bool saveWatchPosition;
  final String timezone;
  final String profileVisibility;
  final String messagingPermission;
  final bool showActivityStatus;
  final bool allowProfilePhotoUse;
  final bool twoFactorEnabled;

  factory StudentPreferencesModel.fromJson(Map<String, dynamic> json) {
    return StudentPreferencesModel(
      notifyLessons: _asBool(json['notify_lessons'], defaultValue: false),
      notifyAssignments: _asBool(json['notify_assignments']),
      notifyAssignmentReminders: _asBool(json['notify_assignment_reminders']),
      notifyQuizzes: _asBool(json['notify_quizzes']),
      notifyQuizReminders: _asBool(json['notify_quiz_reminders']),
      notifyGrades: _asBool(json['notify_grades']),
      notifyMessages: _asBool(json['notify_messages']),
      notifyAnnouncements: _asBool(json['notify_announcements']),
      notifyPlatformUpdates: _asBool(json['notify_platform_updates']),
      notificationSound: _asBool(json['notification_sound']),
      notificationVibration: _asBool(json['notification_vibration']),
      language: json['language']?.toString() ?? 'ar',
      theme: json['theme']?.toString() ?? 'light',
      fontSize: json['font_size']?.toString() ?? 'medium',
      downloadsWifiOnly: _asBool(json['downloads_wifi_only']),
      autoPlayVideo: _asBool(json['auto_play_video'], defaultValue: false),
      defaultVideoQuality: json['default_video_quality']?.toString() ?? 'auto',
      saveWatchPosition: _asBool(json['save_watch_position']),
      timezone: json['timezone']?.toString() ?? 'Asia/Amman',
      profileVisibility:
          json['profile_visibility']?.toString() ?? 'teachers_only',
      messagingPermission:
          json['messaging_permission']?.toString() ?? 'teachers_only',
      showActivityStatus: _asBool(json['show_activity_status']),
      allowProfilePhotoUse: _asBool(json['allow_profile_photo_use']),
      twoFactorEnabled: _asBool(json['two_factor_enabled'], defaultValue: false),
    );
  }

  /// Laravel serializes booleans as `1`/`0` (and sometimes `"1"`/`"true"`),
  /// which the plain `== true` / `!= false` checks silently misread.
  static bool _asBool(dynamic value, {bool defaultValue = true}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'notify_lessons': notifyLessons,
      'notify_assignments': notifyAssignments,
      'notify_assignment_reminders': notifyAssignmentReminders,
      'notify_quizzes': notifyQuizzes,
      'notify_quiz_reminders': notifyQuizReminders,
      'notify_grades': notifyGrades,
      'notify_messages': notifyMessages,
      'notify_announcements': notifyAnnouncements,
      'notify_platform_updates': notifyPlatformUpdates,
      'notification_sound': notificationSound,
      'notification_vibration': notificationVibration,
      'language': language,
      'theme': theme,
      'font_size': fontSize,
      'downloads_wifi_only': downloadsWifiOnly,
      'auto_play_video': autoPlayVideo,
      'default_video_quality': defaultVideoQuality,
      'save_watch_position': saveWatchPosition,
      'timezone': timezone,
      'profile_visibility': profileVisibility,
      'messaging_permission': messagingPermission,
      'show_activity_status': showActivityStatus,
      'allow_profile_photo_use': allowProfilePhotoUse,
      'two_factor_enabled': twoFactorEnabled,
    };
  }

  StudentPreferencesModel copyWith({
    bool? notifyLessons,
    bool? notifyAssignments,
    bool? notifyAssignmentReminders,
    bool? notifyQuizzes,
    bool? notifyQuizReminders,
    bool? notifyGrades,
    bool? notifyMessages,
    bool? notifyAnnouncements,
    bool? notifyPlatformUpdates,
    bool? notificationSound,
    bool? notificationVibration,
    String? language,
    String? theme,
    String? fontSize,
    bool? downloadsWifiOnly,
    bool? autoPlayVideo,
    String? defaultVideoQuality,
    bool? saveWatchPosition,
    String? timezone,
    String? profileVisibility,
    String? messagingPermission,
    bool? showActivityStatus,
    bool? allowProfilePhotoUse,
    bool? twoFactorEnabled,
  }) {
    return StudentPreferencesModel(
      notifyLessons: notifyLessons ?? this.notifyLessons,
      notifyAssignments: notifyAssignments ?? this.notifyAssignments,
      notifyAssignmentReminders:
          notifyAssignmentReminders ?? this.notifyAssignmentReminders,
      notifyQuizzes: notifyQuizzes ?? this.notifyQuizzes,
      notifyQuizReminders: notifyQuizReminders ?? this.notifyQuizReminders,
      notifyGrades: notifyGrades ?? this.notifyGrades,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyAnnouncements: notifyAnnouncements ?? this.notifyAnnouncements,
      notifyPlatformUpdates:
          notifyPlatformUpdates ?? this.notifyPlatformUpdates,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration:
          notificationVibration ?? this.notificationVibration,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      downloadsWifiOnly: downloadsWifiOnly ?? this.downloadsWifiOnly,
      autoPlayVideo: autoPlayVideo ?? this.autoPlayVideo,
      defaultVideoQuality: defaultVideoQuality ?? this.defaultVideoQuality,
      saveWatchPosition: saveWatchPosition ?? this.saveWatchPosition,
      timezone: timezone ?? this.timezone,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      messagingPermission: messagingPermission ?? this.messagingPermission,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      allowProfilePhotoUse: allowProfilePhotoUse ?? this.allowProfilePhotoUse,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }
}
