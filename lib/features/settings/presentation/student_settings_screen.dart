import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/platform/platform_settings_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../data/models/student_settings_model.dart';
import '../widgets/settings_section_cards.dart';
import '../widgets/student_settings_header.dart';
import 'change_password_screen.dart';
import 'edit_personal_info_screen.dart';
import 'student_devices_screen.dart';
import 'student_settings_controller.dart';

class StudentSettingsScreen extends ConsumerStatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  ConsumerState<StudentSettingsScreen> createState() =>
      _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends ConsumerState<StudentSettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentSettingsControllerProvider.notifier).load();
      _loadVersion();
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null || !mounted) {
      return;
    }
    await ref
        .read(studentSettingsControllerProvider.notifier)
        .uploadAvatar(file.path);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل خروج', style: TextStyle(color: Color(0xFF991B1B))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هذا الإجراء قد يكون نهائياً. اكتب «حذف» وأدخل كلمة المرور للتأكيد.'),
            const SizedBox(height: 12),
            TextField(
              controller: confirmationController,
              decoration: const InputDecoration(labelText: 'اكتب: حذف'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف الحساب', style: TextStyle(color: Color(0xFF991B1B))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    if (confirmationController.text.trim() != 'حذف') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب «حذف» للتأكيد')),
      );
      return;
    }

    final success = await ref.read(studentSettingsControllerProvider.notifier).deleteAccount(
          passwordController.text,
        );
    if (success && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
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

  void _toggleAllNotifications(StudentPreferencesModel prefs) {
    final enable = !_allNotificationsEnabled(prefs);
    ref.read(studentSettingsControllerProvider.notifier).updatePreferencesBatch({
      'notify_lessons': enable,
      'notify_assignments': enable,
      'notify_assignment_reminders': enable,
      'notify_quizzes': enable,
      'notify_quiz_reminders': enable,
      'notify_grades': enable,
      'notify_messages': enable,
      'notify_announcements': enable,
      'notify_platform_updates': enable,
      'notification_sound': enable,
      'notification_vibration': enable,
    });
  }

  Future<void> _openContact(BuildContext context, String? email) async {
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بريد الدعم غير متوفر حالياً')),
      );
      return;
    }

    final uri = Uri(scheme: 'mailto', path: email);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تواصل معنا: $email')),
      );
    }
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentSettingsControllerProvider);
    final authState = ref.watch(authControllerProvider);

    ref.listen(studentSettingsControllerProvider, (previous, next) {
      if (next.errorMessage?.contains('انتهت الجلسة') == true && mounted) {
        ref.read(authControllerProvider.notifier).logout();
        context.go(AppRoutes.login);
      }
      if (next.actionMessage != null &&
          next.actionMessage != previous?.actionMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.actionMessage!)),
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          next.status != FeatureLoadStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      }
    });

    return Scaffold(
      body: _buildBody(state, authState.status == AuthStatus.loading),
    );
  }

  Widget _buildBody(StudentSettingsState state, bool isLoggingOut) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const LoadingWidget(message: 'جاري تحميل الإعدادات...');
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'تعذر تحميل الإعدادات',
          onRetry: () => ref.read(studentSettingsControllerProvider.notifier).load(),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final settings = state.settings;
        if (settings == null) {
          return ErrorView(
            message: 'تعذر تحميل الإعدادات',
            onRetry: () => ref.read(studentSettingsControllerProvider.notifier).load(),
          );
        }
        return _buildContent(settings, state, isLoggingOut);
    }
  }

  Widget _buildContent(
    StudentSettingsModel settings,
    StudentSettingsState state,
    bool isLoggingOut,
  ) {
    final metrics = AppLayoutMetrics.of(context);
    const cardGap = 8.0;

    Widget spaced(Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: cardGap),
          child: child,
        );

    final profilePhoto = ProfilePhotoCard(
      profile: settings.profile,
      isUploading: state.isUploadingAvatar,
      onPick: _pickAvatar,
      onDelete: () =>
          ref.read(studentSettingsControllerProvider.notifier).deleteAvatar(),
    );

    final personalInfo = PersonalInformationCard(
      profile: settings.profile,
      onEdit: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditPersonalInfoScreen(profile: settings.profile),
          ),
        );
      },
    );

    final platformSettings = ref.watch(platformSettingsProvider).valueOrNull;

    final security = SecuritySettingsCard(
      profile: settings.profile,
      onChangePassword: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
        );
      },
      onTwoFactorTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('المصادقة الثنائية غير متاحة حالياً على المنصة'),
          ),
        );
      },
      onDevices: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentDevicesScreen(devices: settings.devices),
          ),
        );
      },
      onLogoutAllDevices: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تسجيل الخروج من جميع الأجهزة'),
            content: const Text(
              'سيتم إنهاء جميع الجلسات الأخرى. هل تريد المتابعة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('متابعة'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await ref
              .read(studentSettingsControllerProvider.notifier)
              .logoutAllDevices();
        }
      },
    );

    final appPreferences = AppPreferencesCard(
      preferences: settings.preferences,
      onChanged: (key, value) => ref
          .read(studentSettingsControllerProvider.notifier)
          .updatePreference(key, value),
    );

    final notifications = NotificationSettingsCard(
      preferences: settings.preferences,
      onChanged: (key, value) => ref
          .read(studentSettingsControllerProvider.notifier)
          .updatePreference(key, value),
      onToggleAll: () => _toggleAllNotifications(settings.preferences),
    );

    final privacy = PrivacySettingsCard(
      preferences: settings.preferences,
      onChanged: (key, value) => ref
          .read(studentSettingsControllerProvider.notifier)
          .updatePreference(key, value),
      onDeleteAccount: _confirmDeleteAccount,
    );

    final supportEmail = platformSettings?.supportEmail;

    final support = SupportLegalCard(
      appVersion: _appVersion.isEmpty ? '—' : _appVersion,
      onHelp: () => context.push(AppRoutes.helpCenter),
      onContact: () => _openContact(context, supportEmail),
      onTerms: () => context.push(AppRoutes.termsAndConditions),
      onPrivacy: () => context.push(AppRoutes.privacyPolicy),
      onAbout: () => _showInfoDialog(
        context,
        title: 'حول التطبيق',
        message:
            '${platformSettings?.platformName ?? 'RSHD'}\nالإصدار: ${_appVersion.isEmpty ? '—' : _appVersion}',
      ),
    );

    final logout = SettingsLogoutButton(
      isLoading: isLoggingOut || state.isSaving,
      onPressed: _confirmLogout,
    );

    Widget buildColumns({required bool twoColumns}) {
      if (!twoColumns) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            spaced(profilePhoto),
            spaced(personalInfo),
            spaced(security),
            spaced(appPreferences),
            spaced(notifications),
            spaced(privacy),
            spaced(support),
            logout,
          ],
        );
      }

      // RTL: أول عمود يظهر يميناً — صورة + أمان + إشعارات
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    spaced(profilePhoto),
                    spaced(security),
                    notifications,
                  ],
                ),
              ),
              const SizedBox(width: cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    spaced(personalInfo),
                    spaced(appPreferences),
                    privacy,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: cardGap),
          spaced(support),
          logout,
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(studentSettingsControllerProvider.notifier).load(refresh: true),
      color: AppColors.secondary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: StudentSettingsHeader(
              name: settings.profile.name,
              avatarUrl: settings.profile.avatarUrl,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsiveContent(
              padding: EdgeInsets.fromLTRB(
                metrics.outerHorizontalInset,
                12,
                metrics.outerHorizontalInset,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              child: buildColumns(twoColumns: metrics.isTablet),
            ),
          ),
        ],
      ),
    );
  }
}
