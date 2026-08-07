import 'package:flutter/material.dart';

/// Maps backend icon keys (Material icon names) to [IconData].
class LegalIconMapper {
  LegalIconMapper._();

  static IconData resolve(String? name) {
    if (name == null || name.isEmpty) {
      return Icons.article_outlined;
    }

    return _icons[name] ?? Icons.article_outlined;
  }

  static const Map<String, IconData> _icons = {
    'info_outline': Icons.info_outline,
    'folder_open_outlined': Icons.folder_open_outlined,
    'input_outlined': Icons.input_outlined,
    'track_changes_outlined': Icons.track_changes_outlined,
    'share_outlined': Icons.share_outlined,
    'lock_outline': Icons.lock_outline,
    'smartphone_outlined': Icons.smartphone_outlined,
    'cookie_outlined': Icons.cookie_outlined,
    'child_care_outlined': Icons.child_care_outlined,
    'schedule_outlined': Icons.schedule_outlined,
    'gavel_outlined': Icons.gavel_outlined,
    'delete_outline': Icons.delete_outline,
    'link_outlined': Icons.link_outlined,
    'update_outlined': Icons.update_outlined,
    'mail_outline': Icons.mail_outline,
    'handshake_outlined': Icons.handshake_outlined,
    'menu_book_outlined': Icons.menu_book_outlined,
    'verified_user_outlined': Icons.verified_user_outlined,
    'person_add_outlined': Icons.person_add_outlined,
    'devices_outlined': Icons.devices_outlined,
    'school_outlined': Icons.school_outlined,
    'person_outline': Icons.person_outline,
    'co_present_outlined': Icons.co_present_outlined,
    'block_outlined': Icons.block_outlined,
    'fact_check_outlined': Icons.fact_check_outlined,
    'payments_outlined': Icons.payments_outlined,
    'receipt_long_outlined': Icons.receipt_long_outlined,
    'copyright_outlined': Icons.copyright_outlined,
    'upload_file_outlined': Icons.upload_file_outlined,
    'chat_outlined': Icons.chat_outlined,
    'notifications_outlined': Icons.notifications_outlined,
    'open_in_new_outlined': Icons.open_in_new_outlined,
    'build_circle_outlined': Icons.build_circle_outlined,
    'grade_outlined': Icons.grade_outlined,
    'pause_circle_outline': Icons.pause_circle_outline,
    'logout_outlined': Icons.logout_outlined,
    'shield_outlined': Icons.shield_outlined,
    'balance_outlined': Icons.balance_outlined,
    'cloud_off_outlined': Icons.cloud_off_outlined,
    'account_balance_outlined': Icons.account_balance_outlined,
    'support_agent_outlined': Icons.support_agent_outlined,
    'article_outlined': Icons.article_outlined,
  };
}
