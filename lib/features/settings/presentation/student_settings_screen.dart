import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/platform/platform_settings_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/preferences/app_display_preferences.dart';
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
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).t(strings.logoutTitle)),
        content: Text(AppStrings.of(context).t(strings.logoutConfirm)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.of(context).t(strings.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.of(context).t(strings.logout),
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
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
    ref
        .read(studentSettingsControllerProvider.notifier)
        .updatePreferencesBatch({
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

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final strings = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).t(title)),
        content: Text(AppStrings.of(context).t(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).t(strings.ok)),
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
      final prefs = next.settings?.preferences;
      final previousPrefs = previous?.settings?.preferences;
      if (prefs != null &&
          (previousPrefs == null ||
              prefs.theme != previousPrefs.theme ||
              prefs.language != previousPrefs.language ||
              prefs.fontSize != previousPrefs.fontSize ||
              prefs.autoPlayVideo != previousPrefs.autoPlayVideo ||
              prefs.saveWatchPosition != previousPrefs.saveWatchPosition ||
              prefs.defaultVideoQuality != previousPrefs.defaultVideoQuality)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          if (prefs.theme != previousPrefs?.theme) {
            ref.read(appThemeControllerProvider.notifier).setTheme(prefs.theme);
          }
          if (prefs.language != previousPrefs?.language) {
            ref
                .read(appLocaleControllerProvider.notifier)
                .setLocale(prefs.language);
          }
          ref
              .read(appDisplayPreferencesProvider.notifier)
              .applyFromSettings(
                fontSize: prefs.fontSize,
                autoPlayVideo: prefs.autoPlayVideo,
                saveWatchPosition: prefs.saveWatchPosition,
                videoQuality: prefs.defaultVideoQuality,
              );
        });
      }
      if (!mounted) {
        return;
      }
      if (next.errorMessage?.contains('انتهت الجلسة') == true) {
        ref.read(authControllerProvider.notifier).logout();
        context.go(AppRoutes.login);
      }
      if (next.actionMessage != null &&
          next.actionMessage != previous?.actionMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t(next.actionMessage!))));
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          next.status != FeatureLoadStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).t(next.errorMessage!)),
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
        return LoadingWidget(message: AppStrings.of(context).loadingSettings);
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? AppStrings.of(context).failedSettings,
          onRetry: () =>
              ref.read(studentSettingsControllerProvider.notifier).load(),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final settings = state.settings;
        if (settings == null) {
          return ErrorView(
            message: AppStrings.of(context).failedSettings,
            onRetry: () =>
                ref.read(studentSettingsControllerProvider.notifier).load(),
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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
      },
      onDevices: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentDevicesScreen(devices: settings.devices),
          ),
        );
      },
      onLogoutAllDevices: () async {
        final strings = AppStrings.of(context);
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppStrings.of(context).t(strings.logoutAllTitle)),
            content: Text(AppStrings.of(context).t(strings.logoutAllConfirm)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppStrings.of(context).t(strings.cancel)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.of(context).t(strings.continueAction)),
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
      onChanged: (key, value) {
        if (key == 'theme' && value is String) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            ref.read(appThemeControllerProvider.notifier).setTheme(value);
          });
        }
        if (key == 'language' && value is String) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            ref.read(appLocaleControllerProvider.notifier).setLocale(value);
          });
        }
        final display = ref.read(appDisplayPreferencesProvider.notifier);
        switch (key) {
          case 'font_size' when value is String:
            display.apply(fontSize: value);
          case 'auto_play_video' when value is bool:
            display.apply(autoPlayVideo: value);
          case 'save_watch_position' when value is bool:
            display.apply(saveWatchPosition: value);
          case 'default_video_quality' when value is String:
            display.apply(videoQuality: value);
        }
        ref
            .read(studentSettingsControllerProvider.notifier)
            .updatePreference(key, value);
      },
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
    );

    final support = SupportLegalCard(
      appVersion: _appVersion.isEmpty ? '—' : _appVersion,
      onHelp: () => context.push(AppRoutes.helpCenter),
      onContact: () => context.push(AppRoutes.contactUs),
      onTerms: () => context.push(AppRoutes.termsAndConditions),
      onPrivacy: () => context.push(AppRoutes.privacyPolicy),
      onAbout: () {
        final strings = AppStrings.of(context);
        _showInfoDialog(
          context,
          title: strings.aboutAppTitle,
          message: strings.aboutAppMessage(
            platformSettings?.platformName ?? 'RSHD',
            _appVersion.isEmpty ? '—' : _appVersion,
          ),
        );
      },
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
      onRefresh: () => ref
          .read(studentSettingsControllerProvider.notifier)
          .load(refresh: true),
      color: AppColors.of(context).secondary,
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
