import 'package:flutter/material.dart';
import '../../../core/widgets/form_width.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/security/password_policy.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/password_requirements.dart';
import 'student_settings_controller.dart';
import '../../../core/l10n/app_strings.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _passwordError;
  String? _confirmError;

  bool get _canSave =>
      _currentController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }

    // Warn before sending: what the new password lacks, or a mismatch.
    final strings = AppStrings.of(context);
    final policyError = PasswordPolicy.validate(
      _passwordController.text,
      strings,
    );
    final mismatch = _passwordController.text != _confirmController.text;
    setState(() {
      _passwordError = policyError;
      _confirmError = mismatch ? strings.t('كلمتا المرور غير متطابقتين') : null;
    });
    if (policyError != null || mismatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(policyError ?? strings.t('كلمتا المرور غير متطابقتين')),
          backgroundColor: const Color(0xFFB45309),
        ),
      );
      return;
    }

    final success = await ref
        .read(studentSettingsControllerProvider.notifier)
        .updatePassword(
          currentPassword: _currentController.text,
          password: _passwordController.text,
          confirmation: _confirmController.text,
        );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    VoidCallback? onChanged,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(studentSettingsControllerProvider).isSaving;

    ref.listen(studentSettingsControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).t(next.errorMessage!)),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(AppStrings.of(context).t('تغيير كلمة المرور')),
      ),
      body: FormWidth(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _passwordField(
              controller: _currentController,
              label: AppStrings.of(context).t('كلمة المرور الحالية'),
              obscure: _obscureCurrent,
              toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _passwordController,
              label: AppStrings.of(context).t('كلمة المرور الجديدة'),
              obscure: _obscureNew,
              toggle: () => setState(() => _obscureNew = !_obscureNew),
              onChanged: () => setState(() => _passwordError = null),
              errorText: _passwordError,
            ),
            const SizedBox(height: 10),
            PasswordRequirementsChecklist(password: _passwordController.text),
            const SizedBox(height: 16),
            _passwordField(
              controller: _confirmController,
              label: AppStrings.of(context).t('تأكيد كلمة المرور'),
              obscure: _obscureConfirm,
              toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              onChanged: () => setState(() => _confirmError = null),
              errorText: _confirmError,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: isSaving ? 'جارٍ الحفظ...' : 'حفظ كلمة المرور',
              onPressed: isSaving || !_canSave ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
