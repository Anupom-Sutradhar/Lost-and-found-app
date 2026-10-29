import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../config/theme.dart';


class AuthCard extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onTabChanged;
  final Widget child;

  const AuthCard({
    super.key,
    required this.isLogin,
    required this.onTabChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.06),
            blurRadius: 80,
            offset: const Offset(0, 40),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 36),
          // Logo / brand
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.pillGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.travel_explore_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                AppConstants.appName,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.appTagline,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.slate,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          // Tab row
          _TabRow(isLogin: isLogin, onTabChanged: onTabChanged),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onTabChanged;

  const _TabRow({required this.isLogin, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primarySofter,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _tab(
                context,
                label: 'Login',
                active: isLogin,
                onTap: () => onTabChanged(true),
              ),
            ),
            Expanded(
              child: _tab(
                context,
                label: 'Sign up',
                active: !isLogin,
                onTap: () => onTabChanged(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(13),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : AppColors.slate,
          ),
        ),
      ),
    );
  }
}
