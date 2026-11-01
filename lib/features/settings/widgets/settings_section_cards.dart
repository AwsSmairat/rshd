import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/rshd_loader.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/student_settings_model.dart';
import 'settings_shared_widgets.dart';
import 'student_avatar_image.dart';

const _activeGreen = Color(0xFF17865A);

/// Top of the settings page: who you are, at a glance.
///
/// Replaces both the old navy header and the separate "profile photo" card —
/// the avatar *is* the photo control, tapped directly, so the page opens on
/// the person rather than on a form.
class SettingsProfileHero extends StatelessWidget {
  const SettingsProfileHero({
    super.key,
    required this.profile,
    required this.isUploading,
    required this.onPick,
    required this.onDelete,
    this.onBack,
    this.localAvatarPath,
  });

  final StudentProfileModel profile;
  final String? localAvatarPath;
  final bool isUploading;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onDelete;

  /// Null when the page is a tab root, which hides the back button.
  final VoidCallback? onBack;

  Future<void> _showPhotoOptions(BuildContext context) async {
    final strings = AppStrings.of(context);
    final hasPhoto = profile.avatarUrl != null || localAvatarPath != null;

    // Reuses the option-picker sheet so photo actions look like every other
    // choice on this page.
    final choice = await showSettingsOptionPicker<String>(
      context: context,
      title: strings.profilePhoto,
      current: '',
      options: [
        SettingsPickerOption(value: 'gallery', label: strings.pickFromGallery),
        SettingsPickerOption(value: 'camera', label: strings.takePhoto),
        if (hasPhoto)
          SettingsPickerOption(value: 'delete', label: strings.deletePhoto),
      ],
    );
    switch (choice) {
      case 'gallery':
        onPick(ImageSource.gallery);
      case 'camera':
        onPick(ImageSource.camera);
      case 'delete':
        onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isActive = profile.status == 'active';
    final statusColor = isActive ? _activeGreen : colors.error;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          children: [
            if (onBack != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Material(
                  color: isDark
                      ? colors.white.withValues(alpha: 0.07)
                      : colors.darkGold.withValues(alpha: 0.10),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        isRtl
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: colors.primary,
                        semanticLabel: strings.back,
                      ),
                    ),
                  ),
                ),
              ),

            GestureDetector(
              onTap: isUploading ? null : () => _showPhotoOptions(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.accent, colors.darkGold],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.darkGold.withValues(alpha: 0.25),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? colors.secondaryNavy
                            : const Color(0xFFFBF8F2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          StudentAvatarImage(
                            size: 101,
                            localPath: localAvatarPath,
                            placeholder: Icon(
                              Icons.person_rounded,
                              size: 52,
                              color: colors.darkGold.withValues(alpha: 0.55),
                            ),
                          ),
                          if (isUploading)
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.35),
                              child: Center(
                                child: RshdLoader(
                                  size: 16.1,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 2,
                    end: 2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                        border: Border.all(
                          color: isDark
                              ? colors.background
                              : const Color(0xFFF7F2E9),
                          width: 2.5,
                        ),
                      ),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 15,
                        color: isDark ? const Color(0xFF0B1F3A) : colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textMuted),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${strings.studentRole} · ${strings.statusLabel(profile.status)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small text action aligned with a section label.
class _SectionAction extends StatelessWidget {
  const _SectionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.of(context).darkGold,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        AppStrings.of(context).t(label),
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class PersonalInformationCard extends StatelessWidget {
  const PersonalInformationCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  final StudentProfileModel profile;
  final VoidCallback onEdit;

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '—';
    }
    return value.split('T').first.replaceAll('-', '/');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    // Name and email already headline the page, so they are not repeated here.
    return SettingsSectionCard(
      title: strings.personalInfo,
      icon: Icons.person_outline_rounded,
      trailing: _SectionAction(label: strings.edit, onTap: onEdit),
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.phone_outlined,
            label: strings.phone,
            value: profile.phone ?? '—',
          ),
          SettingsItemTile(
            icon: Icons.cake_outlined,
            label: strings.birthDate,
            value: _formatDate(profile.birthDate),
          ),
          SettingsItemTile(
            icon: Icons.wc_outlined,
            label: strings.gender,
            value: strings.genderLabel(profile.gender),
          ),
          SettingsItemTile(
            icon: Icons.flag_outlined,
            label: strings.country,
            value: profile.country ?? '—',
          ),
          SettingsItemTile(
            icon: Icons.badge_outlined,
            label: strings.studentId,
            value: profile.studentNumber ?? '—',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class SecuritySettingsCard extends StatelessWidget {
  const SecuritySettingsCard({
    super.key,
    required this.profile,
    required this.onChangePassword,
    required this.onDevices,
    required this.onLogoutAllDevices,
  });

  final StudentProfileModel profile;
  final VoidCallback onChangePassword;
  final VoidCallback onDevices;
  final VoidCallback onLogoutAllDevices;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final passwordSetAt = profile.passwordSetAt;

    return SettingsSectionCard(
      title: strings.securityPassword,
      icon: Icons.lock_outline_rounded,
      footer: passwordSetAt == null
          ? null
          : strings.passwordLastUpdated(
              passwordSetAt.split('T').first.replaceAll('-', '/'),
            ),
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.key_rounded,
            label: strings.changePassword,
            onTap: onChangePassword,
          ),
          SettingsItemTile(
            icon: Icons.devices_rounded,
            label: strings.sessionsDevices,
            onTap: onDevices,
          ),
          SettingsItemTile(
            icon: Icons.phonelink_erase_rounded,
            label: strings.logoutAllDevices,
            onTap: onLogoutAllDevices,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class AppPreferencesCard extends StatelessWidget {
  const AppPreferencesCard({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final StudentPreferencesModel preferences;
  final void Function(String key, dynamic value) onChanged;

  Future<void> _pickLanguage(BuildContext context) async {
    final strings = AppStrings.of(context);
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: strings.language,
      current: preferences.language,
      options: [
        SettingsPickerOption(value: 'ar', label: strings.arabic),
        SettingsPickerOption(value: 'en', label: strings.english),
      ],
    );
    if (picked != null && picked != preferences.language) {
      onChanged('language', picked);
    }
  }

  Future<void> _pickTheme(BuildContext context) async {
    final strings = AppStrings.of(context);
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: strings.appearance,
      current: preferences.theme,
      options: [
        SettingsPickerOption(value: 'light', label: strings.lightMode),
        SettingsPickerOption(value: 'dark', label: strings.darkMode),
        SettingsPickerOption(value: 'system', label: strings.systemMode),
      ],
    );
    if (picked != null && picked != preferences.theme) {
      onChanged('theme', picked);
    }
  }

  Future<void> _pickFontSize(BuildContext context) async {
    final strings = AppStrings.of(context);
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: strings.fontSize,
      current: preferences.fontSize,
      options: [
        SettingsPickerOption(value: 'small', label: strings.fontSmall),
        SettingsPickerOption(value: 'medium', label: strings.fontMedium),
        SettingsPickerOption(value: 'large', label: strings.fontLarge),
      ],
    );
    if (picked != null && picked != preferences.fontSize) {
      onChanged('font_size', picked);
    }
  }

  Future<void> _pickVideoQuality(BuildContext context) async {
    final strings = AppStrings.of(context);
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: strings.videoQuality,
      current: preferences.defaultVideoQuality,
      options: [
        SettingsPickerOption(value: 'auto', label: strings.qualityAuto),
        SettingsPickerOption(value: 'low', label: strings.qualityLow),
        SettingsPickerOption(value: 'medium', label: strings.qualityMedium),
        SettingsPickerOption(value: 'high', label: strings.qualityHigh),
      ],
    );
    if (picked != null && picked != preferences.defaultVideoQuality) {
      onChanged('default_video_quality', picked);
    }
  }

  Future<void> _pickTimezone(BuildContext context) async {
    const zones = [
      SettingsPickerOption(value: 'Asia/Amman', label: 'Asia/Amman'),
      SettingsPickerOption(value: 'Asia/Riyadh', label: 'Asia/Riyadh'),
      SettingsPickerOption(value: 'Asia/Dubai', label: 'Asia/Dubai'),
      SettingsPickerOption(value: 'Africa/Cairo', label: 'Africa/Cairo'),
      SettingsPickerOption(value: 'UTC', label: 'UTC'),
    ];
    final current = zones.any((z) => z.value == preferences.timezone)
        ? preferences.timezone
        : zones.first.value;
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: AppStrings.of(context).timezone,
      current: current,
      options: zones,
    );
    if (picked != null && picked != preferences.timezone) {
      onChanged('timezone', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SettingsSectionCard(
      title: strings.appPreferences,
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.translate_rounded,
            label: strings.language,
            value: strings.languageLabel(preferences.language),
            onTap: () => _pickLanguage(context),
          ),
          SettingsItemTile(
            icon: preferences.theme == 'dark'
                ? Icons.dark_mode_outlined
                : preferences.theme == 'system'
                ? Icons.brightness_auto_outlined
                : Icons.light_mode_outlined,
            label: strings.appearance,
            value: strings.themeLabel(preferences.theme),
            onTap: () => _pickTheme(context),
          ),
          SettingsItemTile(
            icon: Icons.text_fields_rounded,
            label: strings.fontSize,
            value: strings.fontLabel(preferences.fontSize),
            onTap: () => _pickFontSize(context),
          ),
          SettingsItemTile(
            icon: Icons.high_quality_outlined,
            label: strings.videoQuality,
            value: strings.qualityLabel(preferences.defaultVideoQuality),
            onTap: () => _pickVideoQuality(context),
          ),
          SettingsSwitchTile(
            icon: Icons.play_circle_outline_rounded,
            label: strings.autoPlayVideo,
            value: preferences.autoPlayVideo,
            onChanged: (v) => onChanged('auto_play_video', v),
          ),
          SettingsSwitchTile(
            icon: Icons.history_rounded,
            label: strings.saveWatchPosition,
            value: preferences.saveWatchPosition,
            onChanged: (v) => onChanged('save_watch_position', v),
          ),
          SettingsItemTile(
            icon: Icons.public_rounded,
            label: strings.timezone,
            value: preferences.timezone,
            onTap: () => _pickTimezone(context),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsCard extends StatelessWidget {
  const NotificationSettingsCard({
    super.key,
    required this.preferences,
    required this.onChanged,
    required this.onToggleAll,
  });

  final StudentPreferencesModel preferences;
  final void Function(String key, dynamic value) onChanged;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final p = preferences;
    final flags = [
      p.notifyLessons,
      p.notifyAssignments,
      p.notifyAssignmentReminders,
      p.notifyQuizzes,
      p.notifyQuizReminders,
      p.notifyGrades,
      p.notifyMessages,
      p.notifyAnnouncements,
      p.notifyPlatformUpdates,
      p.notificationSound,
      p.notificationVibration,
    ];
    final enabled = flags.where((f) => f).length;

    // One master switch up front; the eleven individual switches sit behind a
    // single expandable row instead of filling the screen.
    return SettingsSectionCard(
      title: strings.notifications,
      icon: Icons.notifications_none_rounded,
      child: Column(
        children: [
          SettingsSwitchTile(
            icon: Icons.notifications_active_outlined,
            label: strings.allNotifications,
            value: _allNotificationsEnabled(p),
            onChanged: (_) => onToggleAll(),
          ),
          SettingsExpandableRow(
            icon: Icons.tune_rounded,
            label: strings.customizeNotifications,
            value: strings.enabledOf(enabled, flags.length),
            children: [
              SettingsSwitchTile(
                label: strings.notifyNewLessons,
                value: p.notifyLessons,
                onChanged: (v) => onChanged('notify_lessons', v),
              ),
              SettingsSwitchTile(
                label: strings.notifyAssignments,
                value: p.notifyAssignments,
                onChanged: (v) => onChanged('notify_assignments', v),
              ),
              SettingsSwitchTile(
                label: strings.notifyAssignmentReminders,
                value: p.notifyAssignmentReminders,
                onChanged: (v) => onChanged('notify_assignment_reminders', v),
              ),
              SettingsSwitchTile(
                label: strings.notifyQuizzes,
                value: p.notifyQuizzes,
                onChanged: (v) => onChanged('notify_quizzes', v),
              ),
              SettingsSwitchTile(
                label: strings.notifyQuizReminders,
                value: p.notifyQuizReminders,
                onChanged: (v) => onChanged('notify_quiz_reminders', v),
              ),
              SettingsSwitchTile(
                label: strings.notifyGrades,
                value: p.notifyGrades,
                onChanged: (v) => onChanged('notify_grades', v),
              ),
              SettingsSwitchTile(
                label: strings.notifyMessages,
                value: p.notifyMessages,
                onChanged: (v) => onChanged('notify_messages', v),
              ),
              SettingsSwitchTile(
                label: strings.notifyAnnouncements,
                value: p.notifyAnnouncements,
                onChanged: (v) => onChanged('notify_announcements', v),
              ),
              SettingsSwitchTile(
                label: strings.notifyPlatformUpdates,
                value: p.notifyPlatformUpdates,
                onChanged: (v) => onChanged('notify_platform_updates', v),
              ),
              SettingsSwitchTile(
                label: strings.sound,
                value: p.notificationSound,
                onChanged: (v) => onChanged('notification_sound', v),
              ),
              SettingsSwitchTile(
                label: strings.vibration,
                value: p.notificationVibration,
                onChanged: (v) => onChanged('notification_vibration', v),
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrivacySettingsCard extends StatelessWidget {
  const PrivacySettingsCard({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final StudentPreferencesModel preferences;
  final void Function(String key, dynamic value) onChanged;

  Future<void> _pickProfileVisibility(BuildContext context) async {
    final strings = AppStrings.of(context);
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: strings.whoCanSeeProfile,
      current: preferences.profileVisibility,
      options: [
        SettingsPickerOption(value: 'everyone', label: strings.everyone),
        SettingsPickerOption(
          value: 'teachers_only',
          label: strings.teachersOnly,
        ),
        SettingsPickerOption(value: 'private', label: strings.private),
      ],
    );
    if (picked != null && picked != preferences.profileVisibility) {
      onChanged('profile_visibility', picked);
    }
  }

  Future<void> _pickMessagingPermission(BuildContext context) async {
    final strings = AppStrings.of(context);
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: strings.whoCanMessage,
      current: preferences.messagingPermission,
      options: [
        SettingsPickerOption(value: 'everyone', label: strings.everyone),
        SettingsPickerOption(
          value: 'teachers_only',
          label: strings.teachersOnly,
        ),
        SettingsPickerOption(value: 'nobody', label: strings.nobody),
      ],
    );
    if (picked != null && picked != preferences.messagingPermission) {
      onChanged('messaging_permission', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SettingsSectionCard(
      title: strings.privacy,
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.visibility_outlined,
            label: strings.whoCanSeeProfile,
            value: strings.visibilityLabel(preferences.profileVisibility),
            onTap: () => _pickProfileVisibility(context),
          ),
          SettingsItemTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: strings.whoCanMessage,
            value: strings.messagingLabel(preferences.messagingPermission),
            onTap: () => _pickMessagingPermission(context),
          ),
          SettingsSwitchTile(
            icon: Icons.circle_outlined,
            label: strings.showActivityStatus,
            value: preferences.showActivityStatus,
            onChanged: (v) => onChanged('show_activity_status', v),
          ),
          SettingsSwitchTile(
            icon: Icons.portrait_outlined,
            label: strings.allowProfilePhotoUse,
            value: preferences.allowProfilePhotoUse,
            onChanged: (v) => onChanged('allow_profile_photo_use', v),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

bool _allNotificationsEnabled(StudentPreferencesModel prefs) =>
    prefs.notifyLessons &&
    prefs.notifyAssignments &&
    prefs.notifyAssignmentReminders &&
    prefs.notifyQuizzes &&
    prefs.notifyQuizReminders &&
    prefs.notifyGrades &&
    prefs.notifyMessages &&
    prefs.notifyAnnouncements &&
    prefs.notifyPlatformUpdates &&
    prefs.notificationSound &&
    prefs.notificationVibration;

class SupportLegalCard extends StatelessWidget {
  const SupportLegalCard({
    super.key,
    required this.appVersion,
    this.onHelp,
    this.onContact,
    this.onTerms,
    this.onPrivacy,
    this.onAbout,
  });

  final String appVersion;
  final VoidCallback? onHelp;
  final VoidCallback? onContact;
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;
  final VoidCallback? onAbout;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SettingsSectionCard(
      title: strings.supportAndInfo,
      icon: Icons.support_agent_rounded,
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.help_outline_rounded,
            label: strings.helpCenter,
            onTap: onHelp,
          ),
          SettingsItemTile(
            icon: Icons.mail_outline_rounded,
            label: strings.contactUs,
            onTap: onContact,
          ),
          SettingsItemTile(
            icon: Icons.description_outlined,
            label: strings.terms,
            onTap: onTerms,
          ),
          SettingsItemTile(
            icon: Icons.privacy_tip_outlined,
            label: strings.privacyPolicy,
            onTap: onPrivacy,
          ),
          SettingsItemTile(
            icon: Icons.info_outline_rounded,
            label: strings.aboutAppTitle,
            value: appVersion,
            onTap: onAbout,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

/// Quiet, unmistakable exit: tinted rather than a solid red slab, so it reads
/// as available without shouting over the rest of the page.
class SettingsLogoutButton extends StatelessWidget {
  const SettingsLogoutButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);

    return Material(
      color: colors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.error.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                RshdLoader(size: 11.2, color: colors.error)
              else
                Icon(Icons.logout_rounded, size: 20, color: colors.error),
              const SizedBox(width: 10),
              Text(
                isLoading ? strings.loggingOut : strings.logout,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
