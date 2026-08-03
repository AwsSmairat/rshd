import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../subjects/presentation/subjects_controller.dart';
import '../../subjects/widgets/subjects_header.dart';
import '../data/technical_support_model.dart';
import '../presentation/technical_support_controller.dart';

class TechnicalSupportScreen extends ConsumerStatefulWidget {
  const TechnicalSupportScreen({super.key});

  @override
  ConsumerState<TechnicalSupportScreen> createState() =>
      _TechnicalSupportScreenState();
}

class _TechnicalSupportScreenState
    extends ConsumerState<TechnicalSupportScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(technicalSupportControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن تكون الرسالة 3 أحرف على الأقل')),
      );
      return;
    }

    try {
      await ref
          .read(technicalSupportControllerProvider.notifier)
          .sendMessage(message);
      if (!mounted) return;
      _messageController.clear();
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message.isNotEmpty ? error.message : 'تعذر إرسال الرسالة',
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicalSupportControllerProvider);
    final metrics = AppLayoutMetrics.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (state.status) {
        FeatureLoadStatus.initial || FeatureLoadStatus.loading =>
          const LoadingWidget(message: 'جاري تحميل الدعم الفني...'),
        FeatureLoadStatus.error => ErrorView(
            message: state.errorMessage ?? 'تعذر تحميل الدعم الفني',
            onRetry: () => ref
                .read(technicalSupportControllerProvider.notifier)
                .load(refresh: true),
          ),
        FeatureLoadStatus.empty || FeatureLoadStatus.loaded => Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(technicalSupportControllerProvider.notifier)
                      .load(refresh: true),
                  color: AppColors.secondary,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(
                        child: SubjectsHeader(
                          title: 'الدعم الفني',
                          backgroundIcon: Icons.support_agent_outlined,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: ResponsiveContent(
                          padding: EdgeInsets.fromLTRB(
                            metrics.outerHorizontalInset,
                            12,
                            metrics.outerHorizontalInset,
                            12,
                          ),
                          child: _buildStatusBanner(state.conversation),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: ResponsiveContent(
                          padding: EdgeInsets.symmetric(
                            horizontal: metrics.outerHorizontalInset,
                          ),
                          child: _buildMessages(state.conversation),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.paddingOf(context).bottom + 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildComposer(state),
            ],
          ),
      },
    );
  }

  Widget _buildStatusBanner(SupportConversationModel? conversation) {
    final ticket = conversation?.ticket;

    if (ticket == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          'ابدأ محادثة جديدة مع فريق الدعم الفني — سيظهر طلبك لجميع المسؤولين حتى يقبله أحدهم.',
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
      );
    }

    final statusText = switch (ticket.status) {
      'pending' => 'طلبك بانتظار قبول أحد المسؤولين',
      'active' => ticket.assignedAdminName != null
          ? 'يتابع محادثتك: ${ticket.assignedAdminName}'
          : 'محادثة جارية مع الدعم الفني',
      'closed' => 'تم إنهاء هذه المحادثة — يمكنك بدء محادثة جديدة',
      _ => ticket.statusLabel,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        statusText,
        style: AppTextStyles.body.copyWith(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessages(SupportConversationModel? conversation) {
    final messages = conversation?.messages ?? const [];

    if (messages.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          'لا توجد رسائل بعد. اكتب رسالتك الأولى أدناه.',
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: messages.map(_buildMessageBubble).toList(),
    );
  }

  Widget _buildMessageBubble(SupportMessageModel message) {
    final time = message.createdAt != null
        ? DateFormat('d/M HH:mm', 'ar').format(message.createdAt!.toLocal())
        : '';

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isMine
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: message.isMine
                ? AppColors.primary.withValues(alpha: 0.2)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMine && (message.senderName?.isNotEmpty ?? false))
              Text(
                message.senderName!,
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGold,
                ),
              ),
            Text(
              message.body,
              style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                time,
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(TechnicalSupportState state) {
    final ticket = state.conversation?.ticket;
    final canSend = ticket == null || ticket.isOpen;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canSend && !state.sending,
              maxLines: 4,
              minLines: 1,
              maxLength: 2000,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: canSend
                    ? 'اكتب رسالتك للدعم الفني...'
                    : 'المحادثة منتهية — ابدأ برسالة جديدة',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: canSend && !state.sending ? _sendMessage : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(52, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: state.sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
