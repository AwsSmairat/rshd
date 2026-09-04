import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/models/student_settings_model.dart';
import 'student_settings_controller.dart';
import '../../../core/l10n/app_strings.dart';

class EditPersonalInfoScreen extends ConsumerStatefulWidget {
  const EditPersonalInfoScreen({super.key, required this.profile});

  final StudentProfileModel profile;

  @override
  ConsumerState<EditPersonalInfoScreen> createState() =>
      _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState
    extends ConsumerState<EditPersonalInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _countryController;
  late final TextEditingController _emailController;
  String? _birthDate;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _countryController = TextEditingController(
      text: widget.profile.country ?? '',
    );
    _emailController = TextEditingController(text: widget.profile.email);
    _birthDate = widget.profile.birthDate;
    _gender = widget.profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final initial = _birthDate != null ? DateTime.tryParse(_birthDate!) : null;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).t('الاسم مطلوب'))));
      return;
    }

    final success = await ref
        .read(studentSettingsControllerProvider.notifier)
        .updateProfile(
          name: name,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          birthDate: _birthDate,
          gender: _gender,
          country: _countryController.text.trim().isEmpty
              ? null
              : _countryController.text.trim(),
        );

    if (success && mounted) {
      Navigator.pop(context);
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
            content: Text(AppStrings.of(context).t(next.errorMessage!)),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).t('تعديل المعلومات الشخصية'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppTextField(controller: _nameController, label: AppStrings.of(context).t('الاسم الكامل')),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            readOnly: true,
            decoration: InputDecoration(labelText: AppStrings.of(context).t('البريد الإلكتروني')),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _phoneController,
            label: AppStrings.of(context).t('رقم الهاتف'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.of(context).t('تاريخ الميلاد')),
            subtitle: Text(AppStrings.of(context).t(_birthDate ?? '—')),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickBirthDate,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: InputDecoration(labelText: AppStrings.of(context).t('الجنس')),
            items: [
              DropdownMenuItem(value: 'male', child: Text(AppStrings.of(context).t('ذكر'))),
              DropdownMenuItem(value: 'female', child: Text(AppStrings.of(context).t('أنثى'))),
            ],
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 16),
          AppTextField(controller: _countryController, label: AppStrings.of(context).t('الدولة')),
          const SizedBox(height: 24),
          AppButton(
            label: isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
            onPressed: isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}
