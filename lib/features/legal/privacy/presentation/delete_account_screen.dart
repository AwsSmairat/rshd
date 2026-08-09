import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../settings/presentation/student_settings_controller.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _acknowledged = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_acknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تأكيد فهمك لعواقب حذف الحساب')),
      );
      return;
    }

    if (_confirmationController.text.trim() != 'حذف') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اكتب «حذف» للتأكيد')));
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('كلمة المرور مطلوبة')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حذف الحساب'),
        content: const Text(
          'هل أنت متأكد؟ قد يكون هذا الإجراء نهائياً ولا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف نهائي',
              style: TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await ref
        .read(studentSettingsControllerProvider.notifier)
        .deleteAccount(_passwordController.text);

    if (success && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(studentSettingsControllerProvider).isSaving;

    ref.listen(studentSettingsControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حذف الحساب'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Text(
              'تحذير: عند حذف حسابك، قد تُزال بياناتك الشخصية والتفضيلات '
              'والجلسات. قد نحتفظ ببعض السجلات إذا فرض القانون ذلك.',
              style: TextStyle(height: 1.55, color: Color(0xFF991B1B)),
            ),
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: _acknowledged,
            onChanged: (value) =>
                setState(() => _acknowledged = value ?? false),
            title: const Text('أفهم أن حذف الحساب قد يكون نهائياً'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          AppTextField(controller: _confirmationController, label: 'اكتب: حذف'),
          const SizedBox(height: 16),
          AppTextField(
            controller: _passwordController,
            label: 'كلمة المرور',
            obscureText: true,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: isSaving ? 'جارٍ الحذف...' : 'تأكيد حذف الحساب',
            onPressed: isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
