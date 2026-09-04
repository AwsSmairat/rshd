import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/widgets/profile_detail_row.dart';
import '../data/models/student_settings_model.dart';
import 'settings_shared_widgets.dart';

class ProfilePhotoCard extends StatelessWidget {
  const ProfilePhotoCard({
    super.key,
    required this.profile,
    required this.isUploading,
    required this.onPick,
    required this.onDelete,
  });

  final StudentProfileModel profile;
  final bool isUploading;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onDelete;

  Future<void> _showPicker(BuildContext context) async {
    final strings = AppStrings.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppStrings.of(context).t(strings.pickFromGallery)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(AppStrings.of(context).t(strings.takePhoto)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              if (profile.avatarUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFF991B1B),
                  ),
                  title: Text(AppStrings.of(context).t(strings.deletePhoto)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      onPick(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SettingsSectionCard(
      title: strings.profilePhoto,
      icon: Icons.account_circle_outlined,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.of(context).background,
                  border: Border.all(
                    color: AppColors.of(context).accent,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: profile.avatarUrl != null
                    ? Image.network(profile.avatarUrl!, fit: BoxFit.cover)
                    : Icon(
                        Icons.person_outline,
                        size: 48,
                        color: AppColors.of(
                          context,
                        ).textMuted.withValues(alpha: 0.7),
                      ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).darkGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.of(context).accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(AppStrings.of(context).t(strings.changePhotoHint),
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 13, color: AppColors.of(context).textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isUploading ? null : () => _showPicker(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.of(context).darkGold,
              side: BorderSide(color: AppColors.of(context).darkGold),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppStrings.of(context).t(strings.changePhoto)),
          ),
        ],
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
    return value.replaceAll('-', '/');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SettingsSectionCard(
      title: strings.personalInfo,
      icon: Icons.person_outline,
      trailing: TextButton(onPressed: onEdit, child: Text(AppStrings.of(context).t(strings.edit))),
      child: Column(
        children: [
          ProfileDetailRow(
            dense: true,
            icon: Icons.badge_outlined,
            label: strings.fullName,
            value: profile.name,
          ),
          ProfileDetailRow(
            dense: true,
            icon: Icons.email_outlined,
            label: strings.email,
            value: profile.email,
          ),
          ProfileDetailRow(
            dense: true,
            icon: Icons.phone_outlined,
            label: strings.phone,
            value: profile.phone ?? '—',
          ),
          ProfileDetailRow(
            dense: true,
            icon: Icons.cake_outlined,
            label: strings.birthDate,
            value: _formatDate(profile.birthDate),
          ),
          ProfileDetailRow(
            dense: true,
            icon: Icons.wc_outlined,
            label: strings.gender,
            value: strings.genderLabel(profile.gender),
          ),
          ProfileDetailRow(
            dense: true,
            icon: Icons.flag_outlined,
            label: strings.country,
            value: profile.country ?? '—',
          ),
          ProfileDetailRow(
            dense: true,
            icon: Icons.numbers_outlined,
            label: strings.studentId,
            value: profile.studentNumber ?? '—',
          ),
          ProfileDetailRow(
            dense: true,
            icon: Icons.verified_user_outlined,
            label: strings.accountStatus,
            value: strings.statusLabel(profile.status),
            valueColor: profile.status == 'active'
                ? const Color(0xFF166534)
                : const Color(0xFF991B1B),
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
    return SettingsSectionCard(
      title: strings.securityPassword,
      icon: Icons.lock_outline,
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.vpn_key_outlined,
            label: strings.changePassword,
            onTap: onChangePassword,
          ),
          SettingsItemTile(
            icon: Icons.devices_outlined,
            label: strings.sessionsDevices,
            onTap: onDevices,
          ),
          SettingsItemTile(
            icon: Icons.logout_outlined,
            label: strings.logoutAllDevices,
            onTap: onLogoutAllDevices,
            showDivider: false,
          ),
          if (profile.passwordSetAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(AppStrings.of(context).t(strings.passwordLastUpdated(
                  profile.passwordSetAt!.split('T').first.replaceAll('-', '/'),
                )),
                style: AppTextStyles.bodyOf(context).copyWith(
                  fontSize: 12,
                  color: AppColors.of(context).textMuted,
                ),
              ),
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
      icon: Icons.tune_outlined,
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.language_outlined,
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
            icon: Icons.format_size_outlined,
            label: strings.fontSize,
            value: strings.fontLabel(preferences.fontSize),
            onTap: () => _pickFontSize(context),
          ),
          SettingsSwitchTile(
            label: strings.autoPlayVideo,
            value: preferences.autoPlayVideo,
            onChanged: (v) => onChanged('auto_play_video', v),
          ),
          SettingsItemTile(
            icon: Icons.high_quality_outlined,
            label: strings.videoQuality,
            value: strings.qualityLabel(preferences.defaultVideoQuality),
            onTap: () => _pickVideoQuality(context),
          ),
          SettingsSwitchTile(
            label: strings.saveWatchPosition,
            value: preferences.saveWatchPosition,
            onChanged: (v) => onChanged('save_watch_position', v),
          ),
          SettingsItemTile(
            icon: Icons.schedule_outlined,
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

  bool get _allEnabled => _allNotificationsEnabled(preferences);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SettingsSectionCard(
      title: strings.notifications,
      icon: Icons.notifications_outlined,
      trailing: TextButton(
        onPressed: onToggleAll,
        child: Text(AppStrings.of(context).t(_allEnabled ? strings.disableAll : strings.enableAll)),
      ),
      child: Column(
        children: [
          SettingsSwitchTile(
            label: strings.notifyNewLessons,
            value: preferences.notifyLessons,
            onChanged: (v) => onChanged('notify_lessons', v),
          ),
          SettingsSwitchTile(
            label: strings.notifyAssignments,
            value: preferences.notifyAssignments,
            onChanged: (v) => onChanged('notify_assignments', v),
          ),
          SettingsSwitchTile(
            label: strings.notifyAssignmentReminders,
            value: preferences.notifyAssignmentReminders,
            onChanged: (v) => onChanged('notify_assignment_reminders', v),
          ),
          SettingsSwitchTile(
            label: strings.notifyQuizzes,
            value: preferences.notifyQuizzes,
            onChanged: (v) => onChanged('notify_quizzes', v),
          ),
          SettingsSwitchTile(
            label: strings.notifyQuizReminders,
            value: preferences.notifyQuizReminders,
            onChanged: (v) => onChanged('notify_quiz_reminders', v),
          ),
          SettingsSwitchTile(
            label: strings.notifyGrades,
            value: preferences.notifyGrades,
            onChanged: (v) => onChanged('notify_grades', v),
          ),
          SettingsSwitchTile(
            label: strings.notifyMessages,
            value: preferences.notifyMessages,
            onChanged: (v) => onChanged('notify_messages', v),
          ),
          SettingsSwitchTile(
            label: strings.notifyAnnouncements,
            value: preferences.notifyAnnouncements,
            onChanged: (v) => onChanged('notify_announcements', v),
          ),
          SettingsSwitchTile(
            label: strings.notifyPlatformUpdates,
            value: preferences.notifyPlatformUpdates,
            onChanged: (v) => onChanged('notify_platform_updates', v),
          ),
          SettingsSwitchTile(
            label: strings.sound,
            value: preferences.notificationSound,
            onChanged: (v) => onChanged('notification_sound', v),
          ),
          SettingsSwitchTile(
            label: strings.vibration,
            value: preferences.notificationVibration,
            onChanged: (v) => onChanged('notification_vibration', v),
            showDivider: false,
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
            icon: Icons.chat_outlined,
            label: strings.whoCanMessage,
            value: strings.messagingLabel(preferences.messagingPermission),
            onTap: () => _pickMessagingPermission(context),
          ),
          SettingsSwitchTile(
            label: strings.showActivityStatus,
            value: preferences.showActivityStatus,
            onChanged: (v) => onChanged('show_activity_status', v),
          ),
          SettingsSwitchTile(
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
      icon: Icons.help_outline,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SupportChip(
            icon: Icons.help_center_outlined,
            label: strings.helpCenter,
            onTap: onHelp,
          ),
          _SupportChip(
            icon: Icons.contact_support_outlined,
            label: strings.contactUs,
            onTap: onContact,
          ),
          _SupportChip(
            icon: Icons.description_outlined,
            label: strings.terms,
            onTap: onTerms,
          ),
          _SupportChip(
            icon: Icons.privacy_tip_outlined,
            label: strings.privacyPolicy,
            onTap: onPrivacy,
          ),
          _SupportChip(
            icon: Icons.info_outline,
            label: strings.aboutApp(appVersion),
            onTap: onAbout,
          ),
        ],
      ),
    );
  }
}

class _SupportChip extends StatelessWidget {
  const _SupportChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.of(context).darkGold, size: 24),
              const SizedBox(height: 8),
              Text(AppStrings.of(context).t(label),
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF991B1B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(AppStrings.of(context).t(isLoading
              ? AppStrings.of(context).loggingOut
              : AppStrings.of(context).logout),
        ),
      ),
    );
  }
}
