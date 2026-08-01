import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('اختيار من المعرض'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('التقاط صورة'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              if (profile.avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFF991B1B)),
                  title: const Text('حذف الصورة'),
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
    return SettingsSectionCard(
      title: 'الصورة الشخصية',
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
                  color: AppColors.background,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: profile.avatarUrl != null
                    ? Image.network(profile.avatarUrl!, fit: BoxFit.cover)
                    : Icon(
                        Icons.person_outline,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                      ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.darkGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 16),
                ),
              ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'يمكنك تغيير صورتك الشخصية',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isUploading ? null : () => _showPicker(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGold,
              side: const BorderSide(color: AppColors.darkGold),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('تغيير الصورة'),
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
    return SettingsSectionCard(
      title: 'المعلومات الشخصية',
      icon: Icons.person_outline,
      trailing: TextButton(
        onPressed: onEdit,
        child: const Text('تعديل'),
      ),
      child: Column(
        children: [
          ProfileDetailRow(dense: true, icon: Icons.badge_outlined, label: 'الاسم الكامل', value: profile.name),
          ProfileDetailRow(dense: true, icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: profile.email),
          ProfileDetailRow(dense: true, icon: Icons.phone_outlined, label: 'رقم الهاتف', value: profile.phone ?? '—'),
          ProfileDetailRow(dense: true, icon: Icons.cake_outlined, label: 'تاريخ الميلاد', value: _formatDate(profile.birthDate)),
          ProfileDetailRow(dense: true, icon: Icons.wc_outlined, label: 'الجنس', value: profile.genderLabel),
          ProfileDetailRow(dense: true, icon: Icons.flag_outlined, label: 'الدولة', value: profile.country ?? '—'),
          ProfileDetailRow(dense: true, icon: Icons.numbers_outlined, label: 'الرقم التعريفي', value: profile.studentNumber ?? '—'),
          ProfileDetailRow(
            dense: true,
            icon: Icons.verified_user_outlined,
            label: 'حالة الحساب',
            value: profile.statusLabel,
            valueColor: profile.status == 'active' ? const Color(0xFF166534) : const Color(0xFF991B1B),
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
    required this.onTwoFactorTap,
  });

  final StudentProfileModel profile;
  final VoidCallback onChangePassword;
  final VoidCallback onDevices;
  final VoidCallback onLogoutAllDevices;
  final VoidCallback onTwoFactorTap;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'الأمان وكلمة المرور',
      icon: Icons.lock_outline,
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.vpn_key_outlined,
            label: 'تغيير كلمة المرور',
            onTap: onChangePassword,
          ),
          SettingsItemTile(
            icon: Icons.security_outlined,
            label: 'المصادقة الثنائية',
            value: 'غير مفعّلة',
            onTap: onTwoFactorTap,
          ),
          SettingsItemTile(
            icon: Icons.devices_outlined,
            label: 'الجلسات والأجهزة',
            onTap: onDevices,
          ),
          SettingsItemTile(
            icon: Icons.logout_outlined,
            label: 'تسجيل الخروج من جميع الأجهزة',
            onTap: onLogoutAllDevices,
            showDivider: false,
          ),
          if (profile.passwordSetAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'آخر تحديث لكلمة المرور: ${profile.passwordSetAt!.split('T').first.replaceAll('-', '/')}',
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
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
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: 'اللغة',
      current: preferences.language,
      options: const [
        SettingsPickerOption(value: 'ar', label: 'العربية'),
        SettingsPickerOption(value: 'en', label: 'English'),
      ],
    );
    if (picked != null && picked != preferences.language) {
      onChanged('language', picked);
    }
  }

  Future<void> _pickTheme(BuildContext context) async {
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: 'الوضع',
      current: preferences.theme,
      options: const [
        SettingsPickerOption(value: 'light', label: 'الوضع الفاتح'),
        SettingsPickerOption(value: 'dark', label: 'الوضع الداكن'),
        SettingsPickerOption(value: 'system', label: 'حسب النظام'),
      ],
    );
    if (picked != null && picked != preferences.theme) {
      onChanged('theme', picked);
    }
  }

  Future<void> _pickFontSize(BuildContext context) async {
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: 'حجم الخط',
      current: preferences.fontSize,
      options: const [
        SettingsPickerOption(value: 'small', label: 'صغير'),
        SettingsPickerOption(value: 'medium', label: 'متوسط'),
        SettingsPickerOption(value: 'large', label: 'كبير'),
      ],
    );
    if (picked != null && picked != preferences.fontSize) {
      onChanged('font_size', picked);
    }
  }

  Future<void> _pickVideoQuality(BuildContext context) async {
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: 'جودة الفيديو',
      current: preferences.defaultVideoQuality,
      options: const [
        SettingsPickerOption(value: 'auto', label: 'تلقائية'),
        SettingsPickerOption(value: 'low', label: 'منخفضة'),
        SettingsPickerOption(value: 'medium', label: 'متوسطة'),
        SettingsPickerOption(value: 'high', label: 'عالية'),
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
      title: 'المنطقة الزمنية',
      current: current,
      options: zones,
    );
    if (picked != null && picked != preferences.timezone) {
      onChanged('timezone', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'تفضيلات التطبيق',
      icon: Icons.tune_outlined,
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.language_outlined,
            label: 'اللغة',
            value: preferences.language == 'ar' ? 'العربية' : 'English',
            onTap: () => _pickLanguage(context),
          ),
          SettingsItemTile(
            icon: Icons.light_mode_outlined,
            label: 'الوضع',
            value: _themeLabel(preferences.theme),
            onTap: () => _pickTheme(context),
          ),
          SettingsItemTile(
            icon: Icons.format_size_outlined,
            label: 'حجم الخط',
            value: _fontLabel(preferences.fontSize),
            onTap: () => _pickFontSize(context),
          ),
          SettingsSwitchTile(
            label: 'التشغيل التلقائي للفيديو',
            value: preferences.autoPlayVideo,
            onChanged: (v) => onChanged('auto_play_video', v),
          ),
          SettingsItemTile(
            icon: Icons.high_quality_outlined,
            label: 'جودة الفيديو',
            value: _qualityLabel(preferences.defaultVideoQuality),
            onTap: () => _pickVideoQuality(context),
          ),
          SettingsSwitchTile(
            label: 'حفظ آخر موضع مشاهدة',
            value: preferences.saveWatchPosition,
            onChanged: (v) => onChanged('save_watch_position', v),
          ),
          SettingsItemTile(
            icon: Icons.schedule_outlined,
            label: 'المنطقة الزمنية',
            value: preferences.timezone,
            onTap: () => _pickTimezone(context),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  String _themeLabel(String theme) => switch (theme) {
        'dark' => 'الوضع الداكن',
        'system' => 'حسب النظام',
        _ => 'الوضع الفاتح',
      };

  String _fontLabel(String size) => switch (size) {
        'small' => 'صغير',
        'large' => 'كبير',
        _ => 'متوسط',
      };

  String _qualityLabel(String quality) => switch (quality) {
        'low' => 'منخفضة',
        'medium' => 'متوسطة',
        'high' => 'عالية',
        _ => 'تلقائية',
      };
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
    return SettingsSectionCard(
      title: 'الإشعارات',
      icon: Icons.notifications_outlined,
      trailing: TextButton(onPressed: onToggleAll, child: Text(_allEnabled ? 'تعطيل الكل' : 'تفعيل الكل')),
      child: Column(
        children: [
          SettingsSwitchTile(label: 'إشعارات الدروس الجديدة', value: preferences.notifyLessons, onChanged: (v) => onChanged('notify_lessons', v)),
          SettingsSwitchTile(label: 'إشعارات الواجبات', value: preferences.notifyAssignments, onChanged: (v) => onChanged('notify_assignments', v)),
          SettingsSwitchTile(label: 'تذكير موعد تسليم الواجب', value: preferences.notifyAssignmentReminders, onChanged: (v) => onChanged('notify_assignment_reminders', v)),
          SettingsSwitchTile(label: 'إشعارات الاختبارات', value: preferences.notifyQuizzes, onChanged: (v) => onChanged('notify_quizzes', v)),
          SettingsSwitchTile(label: 'تذكير موعد الاختبار', value: preferences.notifyQuizReminders, onChanged: (v) => onChanged('notify_quiz_reminders', v)),
          SettingsSwitchTile(label: 'إشعارات الدرجات', value: preferences.notifyGrades, onChanged: (v) => onChanged('notify_grades', v)),
          SettingsSwitchTile(label: 'إشعارات الرسائل', value: preferences.notifyMessages, onChanged: (v) => onChanged('notify_messages', v)),
          SettingsSwitchTile(label: 'إشعارات الإعلانات', value: preferences.notifyAnnouncements, onChanged: (v) => onChanged('notify_announcements', v)),
          SettingsSwitchTile(label: 'تحديثات المنصة', value: preferences.notifyPlatformUpdates, onChanged: (v) => onChanged('notify_platform_updates', v)),
          SettingsSwitchTile(label: 'الصوت', value: preferences.notificationSound, onChanged: (v) => onChanged('notification_sound', v)),
          SettingsSwitchTile(label: 'الاهتزاز', value: preferences.notificationVibration, onChanged: (v) => onChanged('notification_vibration', v), showDivider: false),
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
    required this.onDeleteAccount,
  });

  final StudentPreferencesModel preferences;
  final void Function(String key, dynamic value) onChanged;
  final VoidCallback onDeleteAccount;

  Future<void> _pickProfileVisibility(BuildContext context) async {
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: 'من يمكنه رؤية الملف',
      current: preferences.profileVisibility,
      options: const [
        SettingsPickerOption(value: 'everyone', label: 'الجميع'),
        SettingsPickerOption(value: 'teachers_only', label: 'المدرسون فقط'),
        SettingsPickerOption(value: 'private', label: 'خاص'),
      ],
    );
    if (picked != null && picked != preferences.profileVisibility) {
      onChanged('profile_visibility', picked);
    }
  }

  Future<void> _pickMessagingPermission(BuildContext context) async {
    final picked = await showSettingsOptionPicker<String>(
      context: context,
      title: 'من يمكنه مراسلتي',
      current: preferences.messagingPermission,
      options: const [
        SettingsPickerOption(value: 'everyone', label: 'الجميع'),
        SettingsPickerOption(value: 'teachers_only', label: 'المدرسون فقط'),
        SettingsPickerOption(value: 'nobody', label: 'لا أحد'),
      ],
    );
    if (picked != null && picked != preferences.messagingPermission) {
      onChanged('messaging_permission', picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'الخصوصية',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          SettingsItemTile(
            icon: Icons.visibility_outlined,
            label: 'من يمكنه رؤية الملف',
            value: _visibilityLabel(preferences.profileVisibility),
            onTap: () => _pickProfileVisibility(context),
          ),
          SettingsItemTile(
            icon: Icons.chat_outlined,
            label: 'من يمكنه مراسلتي',
            value: _messagingLabel(preferences.messagingPermission),
            onTap: () => _pickMessagingPermission(context),
          ),
          SettingsSwitchTile(label: 'إظهار حالة النشاط', value: preferences.showActivityStatus, onChanged: (v) => onChanged('show_activity_status', v)),
          SettingsSwitchTile(label: 'السماح باستخدام الصورة الشخصية', value: preferences.allowProfilePhotoUse, onChanged: (v) => onChanged('allow_profile_photo_use', v), showDivider: false),
          SettingsItemTile(icon: Icons.delete_forever_outlined, label: 'حذف الحساب', value: 'حذف نهائي', valueColor: const Color(0xFF991B1B), onTap: onDeleteAccount, showDivider: false),
        ],
      ),
    );
  }

  String _visibilityLabel(String value) => switch (value) {
        'everyone' => 'الجميع',
        'private' => 'خاص',
        _ => 'المدرسون فقط',
      };

  String _messagingLabel(String value) => switch (value) {
        'everyone' => 'الجميع',
        'nobody' => 'لا أحد',
        _ => 'المدرسون فقط',
      };
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
    return SettingsSectionCard(
      title: 'الدعم والمعلومات',
      icon: Icons.help_outline,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SupportChip(
            icon: Icons.help_center_outlined,
            label: 'مركز المساعدة',
            onTap: onHelp,
          ),
          _SupportChip(
            icon: Icons.contact_support_outlined,
            label: 'تواصل معنا',
            onTap: onContact,
          ),
          _SupportChip(
            icon: Icons.description_outlined,
            label: 'الشروط والأحكام',
            onTap: onTerms,
          ),
          _SupportChip(
            icon: Icons.privacy_tip_outlined,
            label: 'سياسة الخصوصية',
            onTap: onPrivacy,
          ),
          _SupportChip(
            icon: Icons.info_outline,
            label: 'حول التطبيق • $appVersion',
            onTap: onAbout,
          ),
        ],
      ),
    );
  }
}

class _SupportChip extends StatelessWidget {
  const _SupportChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
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
              Icon(icon, color: AppColors.darkGold, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
  const SettingsLogoutButton({super.key, required this.onPressed, this.isLoading = false});

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.logout_rounded),
        label: Text(isLoading ? 'جارٍ تسجيل الخروج...' : 'تسجيل خروج'),
      ),
    );
  }
}
