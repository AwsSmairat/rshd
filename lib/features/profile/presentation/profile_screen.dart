import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../widgets/device_info_card.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  Future<void> _refresh() {
    return ref.read(profileControllerProvider.notifier).load(refresh: true);
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'تسجيل خروج',
                style: TextStyle(color: Color(0xFF991B1B)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);

    ref.listen(profileControllerProvider, (previous, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      body: _buildBody(state, authState.status == AuthStatus.loading),
    );
  }

  Widget _buildBody(ProfileState state, bool isLoggingOut) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const LoadingWidget(message: 'جاري تحميل الملف الشخصي...');
      case FeatureLoadStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'حدث خطأ غير متوقع',
          onRetry: () => ref.read(profileControllerProvider.notifier).load(),
        );
      case FeatureLoadStatus.empty:
      case FeatureLoadStatus.loaded:
        final profile = state.profile;
        if (profile == null) {
          return ErrorView(
            message: 'تعذر تحميل الملف الشخصي',
            onRetry: _refresh,
          );
        }

        final metrics = AppLayoutMetrics.of(context);

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.secondary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  name: profile.name,
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
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: ResponsiveContent(
                    child: ProfileInfoCard(profile: profile),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ResponsiveContent(
                  padding: EdgeInsets.fromLTRB(
                    metrics.outerHorizontalInset,
                    12,
                    metrics.outerHorizontalInset,
                    0,
                  ),
                  child: DeviceInfoCard(device: profile.activeDevice),
                ),
              ),
              SliverToBoxAdapter(
                child: ResponsiveContent(
                  padding: EdgeInsets.fromLTRB(
                    metrics.outerHorizontalInset,
                    20,
                    metrics.outerHorizontalInset,
                    MediaQuery.paddingOf(context).bottom + 28,
                  ),
                  child: ProfileLogoutButton(
                    isLoading: isLoggingOut,
                    onPressed: _confirmLogout,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
