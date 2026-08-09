import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import 'student_settings_controller.dart';

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

  int _passwordStrength(String value) {
    var score = 0;
    if (value.length >= 8) {
      score++;
    }
    if (RegExp(r'[A-Z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      score++;
    }
    return score;
  }

  bool get _canSave {
    final password = _passwordController.text;
    return _currentController.text.isNotEmpty &&
        password.length >= 8 &&
        password == _confirmController.text;
  }

  Future<void> _save() async {
    if (!_canSave) {
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(studentSettingsControllerProvider).isSaving;
    final strength = _passwordStrength(_passwordController.text);

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
      appBar: AppBar(title: const Text('تغيير كلمة المرور')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _passwordField(
            controller: _currentController,
            label: 'كلمة المرور الحالية',
            obscure: _obscureCurrent,
            toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 16),
          _passwordField(
            controller: _passwordController,
            label: 'كلمة المرور الجديدة',
            obscure: _obscureNew,
            toggle: () => setState(() => _obscureNew = !_obscureNew),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: strength / 4,
            color: switch (strength) {
              <= 1 => Colors.red,
              2 => Colors.orange,
              3 => AppColors.darkGold,
              _ => Colors.green,
            },
            backgroundColor: AppColors.background,
          ),
          const SizedBox(height: 8),
          const Text('يجب أن تكون 8 أحرف على الأقل.'),
          const SizedBox(height: 16),
          _passwordField(
            controller: _confirmController,
            label: 'تأكيد كلمة المرور',
            obscure: _obscureConfirm,
            toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: isSaving ? 'جارٍ الحفظ...' : 'حفظ كلمة المرور',
            onPressed: isSaving || !_canSave ? null : _save,
          ),
        ],
      ),
    );
  }
}
