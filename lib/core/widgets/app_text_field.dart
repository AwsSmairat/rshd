import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.errorText,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final String? errorText;

  /// Leading icon; turns gold while the field has focus (see the theme).
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
      ),
    );
  }
}
