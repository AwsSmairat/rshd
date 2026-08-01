import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../subjects/widgets/subjects_header.dart';
import '../notification_navigation.dart';
import '../widgets/notification_card.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsListControllerProvider.notifier).load();
    });
  }

  Future<void> _refresh() {
    return ref
        .read(notificationsListControllerProvider.notifier)
        .load(refresh: true);
  }

  Future<void> _openNotification(int notificationId) async {
    final controller = ref.read(notificationsListControllerProvider.notifier);
    final notification = controller.findById(notificationId);

    if (notification == null) {
      return;
    }

    if (!notification.isRead) {
      final success = await controller.markAsRead(notificationId);
      if (!success && mounted) {
        final error =
            ref.read(notificationsListControllerProvider).errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    }

    if (!mounted) {
      return;
    }

    final latestNotification =
        controller.findById(notificationId) ?? notification;

    NotificationNavigation.open(context, latestNotification);
  }

  void _handleUnauthorized(String? message) {
    if (message != null && message.contains('انتهت الجلسة') && mounted) {
      ref.read(authControllerProvider.notifier).logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsListControllerProvider);

    ref.listen(notificationsListControllerProvider, (previous, next) {
      _handleUnauthorized(next.errorMessage);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.secondary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: SubjectsHeader(
                title: 'الإشعارات',
                backgroundIcon: Icons.notifications_outlined,
              ),
            ),
            _buildContent(state),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(NotificationsListState state) {
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return const SliverFillRemaining(
          child: LoadingWidget(message: 'جاري تحميل الإشعارات...'),
        );
      case FeatureLoadStatus.empty:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('لا توجد إشعارات حالياً')),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          child: ErrorView(
            message: state.errorMessage ?? 'حدث خطأ غير متوقع',
            onRetry: () =>
                ref.read(notificationsListControllerProvider.notifier).load(),
          ),
        );
      case FeatureLoadStatus.loaded:
        final metrics = AppLayoutMetrics.of(context);

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            metrics.outerHorizontalInset,
            16,
            metrics.outerHorizontalInset,
            24,
          ),
          sliver: SliverConstrainedCrossAxis(
            maxExtent: metrics.contentMaxWidth,
            sliver: SliverList.separated(
              itemCount: state.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return NotificationCard(
                  notification: notification,
                  onTap: () => _openNotification(notification.id),
                );
              },
            ),
          ),
        );
    }
  }
}
