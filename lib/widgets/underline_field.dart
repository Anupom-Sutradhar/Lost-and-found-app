import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';


class UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData trailingIcon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTrailingTap;
  final TextCapitalization textCapitalization;

  const UnderlineField({
    super.key,
    required this.controller,
    required this.hint,
    required this.trailingIcon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onSubmitted,
    this.onTrailingTap,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(
          fontSize: 15, color: AppColors.navy, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        hintStyle: GoogleFonts.inter(
            color: AppColors.slateLight, fontSize: 15),
        suffixIcon: GestureDetector(
          onTap: onTrailingTap,
          child: Icon(trailingIcon, color: AppColors.slateLight, size: 20),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border, width: 1.5)),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border, width: 1.5)),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5)),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2)),
      ),
    );
  }
}
