import 'package:flutter/material.dart';

import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/stagger_reveal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/rshd_refresh_indicator.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../notification_navigation.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pill_choice_bar.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/rshd_loader.dart';
import '../../subjects/widgets/subjects_page_header.dart';
import '../../subjects/widgets/subjects_state_views.dart';
import '../data/models/notification_model.dart';
import '../widgets/notification_tile.dart';
import 'notifications_controller.dart';
import '../../../core/l10n/app_strings.dart';

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
        final error = ref
            .read(notificationsListControllerProvider)
            .errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.of(context).t(error))),
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

  NotificationFilter _filter = NotificationFilter.all;
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    final ok = await ref
        .read(notificationsListControllerProvider.notifier)
        .markAllAsRead();
    if (!mounted) return;
    setState(() => _markingAll = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).markAllReadFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsListControllerProvider);
    final strings = AppStrings.of(context);
    final metrics = AppLayoutMetrics.of(context);
    final loaded = state.status == FeatureLoadStatus.loaded;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: RshdRefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(
                child: ResponsiveContent(
                  child: SubjectsPageHeader(
                    title: strings.notificationsTitle,
                    subtitle: loaded
                        ? strings.unreadNotificationsLabel(state.unreadCount)
                        : null,
                    onBack: Navigator.of(context).canPop()
                        ? () => Navigator.of(context).maybePop()
                        : null,
                  ),
                ),
              ),
            ),
            if (loaded) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: PillChoiceBar<NotificationFilter>(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.outerHorizontalInset,
                    ),
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                    choices: [
                      for (final f in NotificationFilter.values)
                        if (f == NotificationFilter.all ||
                            f == NotificationFilter.unread ||
                            state.notifications.any(f.matches))
                          PillChoice(
                            f,
                            f.label(strings),
                            badge: f == NotificationFilter.unread
                                ? state.unreadCount
                                : null,
                          ),
                    ],
                  ),
                ),
              ),
              if (state.unreadCount > 0)
                SliverToBoxAdapter(
                  child: ResponsiveContent(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: _markingAll ? null : _markAllRead,
                        icon: _markingAll
                            ? const RshdLoader(size: 10)
                            : const Icon(Icons.done_all_rounded, size: 18),
                        label: Text(
                          strings.markAllRead,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.of(context).darkGold,
                          minimumSize: const Size(44, 44),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
            _buildContent(state),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(NotificationsListState state) {
    final strings = AppStrings.of(context);
    switch (state.status) {
      case FeatureLoadStatus.initial:
      case FeatureLoadStatus.loading:
        return ResponsiveSliverContent(
          padding: AppLayoutMetrics.of(context).pagePadding(top: 4, bottom: 0),
          sliver: const SliverToBoxAdapter(child: _NotificationsSkeleton()),
        );
      case FeatureLoadStatus.empty:
        return _empty(
          SubjectsEmptyState(
            icon: Icons.notifications_none_rounded,
            message: strings.noNotificationsTitle,
            subtitle: strings.noNotificationsHint,
          ),
        );
      case FeatureLoadStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: state.errorMessage ?? 'حدث خطأ غير متوقع',
            onRetry: () =>
                ref.read(notificationsListControllerProvider.notifier).load(),
          ),
        );
      case FeatureLoadStatus.loaded:
        final shown = state.notifications.where(_filter.matches).toList();
        if (shown.isEmpty) {
          return _empty(
            SubjectsEmptyState(
              icon: Icons.filter_list_rounded,
              message: _filter == NotificationFilter.unread
                  ? strings.unreadNotificationsLabel(0)
                  : strings.noNotificationsInFilter,
              subtitle: '',
              actionLabel: strings.showAllNotifications,
              onAction: () => setState(() => _filter = NotificationFilter.all),
            ),
          );
        }
        final groups = _groupByDay(shown, strings);
        return ResponsiveSliverContent(
          padding: AppLayoutMetrics.of(context).pagePadding(top: 4, bottom: 0),
          sliver: SliverList.separated(
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 22),
            itemBuilder: (context, i) => StaggerReveal(
              order: i,
              child: _GroupCard(
                title: groups[i].$1,
                notifications: groups[i].$2,
                onOpen: _openNotification,
              ),
            ),
          ),
        );
    }
  }

  Widget _empty(Widget child) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(child: child),
    ),
  );

  /// Today / Yesterday / This week / Earlier, newest first, empty groups
  /// left out.
  List<(String, List<NotificationModel>)> _groupByDay(
    List<NotificationModel> items,
    AppStrings strings,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final buckets = <String, List<NotificationModel>>{
      strings.groupToday: [],
      strings.groupYesterday: [],
      strings.groupThisWeek: [],
      strings.groupEarlier: [],
    };
    for (final n in items) {
      final at = DateTime.tryParse(n.createdAt ?? '')?.toLocal();
      final day = at == null ? null : DateTime(at.year, at.month, at.day);
      final age = day == null ? 999 : today.difference(day).inDays;
      final key = switch (age) {
        <= 0 => strings.groupToday,
        1 => strings.groupYesterday,
        < 7 => strings.groupThisWeek,
        _ => strings.groupEarlier,
      };
      buckets[key]!.add(n);
    }
    return [
      for (final e in buckets.entries)
        if (e.value.isNotEmpty) (e.key, e.value),
    ];
  }
}

/// A day's notifications in one rounded card.
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.notifications,
    required this.onOpen,
  });

  final String title;
  final List<NotificationModel> notifications;
  final void Function(int id) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
          child: Text(
            title,
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.textMuted,
              letterSpacing: 0.2,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.primary.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                for (var i = 0; i < notifications.length; i++)
                  NotificationTile(
                    notification: notifications[i],
                    showDivider: i < notifications.length - 1,
                    onTap: () => onOpen(notifications[i].id),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Filter chips above the list.
enum NotificationFilter {
  all,
  unread,
  courses,
  tasks,
  announcements,
  messages;

  bool matches(NotificationModel n) => switch (this) {
    all => true,
    unread => !n.isRead,
    courses => notificationKindOf(n) == NotificationKind.course,
    tasks => notificationKindOf(n) == NotificationKind.task,
    announcements => notificationKindOf(n) == NotificationKind.announcement,
    messages => notificationKindOf(n) == NotificationKind.message,
  };

  String label(AppStrings s) => switch (this) {
    all => s.filterAll,
    unread => s.filterUnread,
    courses => s.filterCourses,
    tasks => s.filterTasks,
    announcements => s.filterAnnouncements,
    messages => s.filterMessages,
  };
}

/// Day groups of notification rows while the list loads.
class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget group(int rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 70, height: 13),
        const SizedBox(height: 10),
        SkeletonCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (var i = 0; i < rows; i++) ...[
                if (i > 0) const SizedBox(height: 18),
                SkeletonListRow(
                  titleWidth: i.isEven ? 200 : 160,
                  subtitleWidth: i.isEven ? 240 : 190,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Skeleton(
      child: Column(children: [group(3), const SizedBox(height: 22), group(2)]),
    );
  }
}
