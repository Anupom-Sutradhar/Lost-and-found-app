import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/underline_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _code = '';
  bool _loading = false;
  bool _obscure = true;
  bool _otpVerified = false;
  String? _error;

  int _resendCooldown = 30;
  Timer? _cooldownTimer;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    if (_code.length < 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      if (!_otpVerified) {
        await auth.service
            .verifyPasswordResetOtp(email: widget.email, token: _code);
        _otpVerified = true;
      }
      await auth.service.updatePassword(_passCtrl.text);
      await auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _otpVerified = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await context
          .read<AuthProvider>()
          .service
          .sendPasswordResetEmail(widget.email);
      _startCooldown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New code sent.')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.18),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Reset password',
                              style:
                                  Theme.of(context).textTheme.displayMedium),
                          const SizedBox(height: 6),
                          Text('Code sent to ${widget.email}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 22),
                          Text('Verification code',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          OtpInput(
                            length: 6,
                            onChanged: (v) => setState(() {
                              _code = v;
                              _error = null;
                            }),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resending || _resendCooldown > 0
                                  ? null
                                  : _resend,
                              child: Text(
                                _resending
                                    ? 'Sending...'
                                    : _resendCooldown > 0
                                        ? 'Resend in ${_resendCooldown}s'
                                        : 'Resend code',
                                style: GoogleFonts.inter(
                                  color: _resendCooldown > 0
                                      ? AppColors.slateLight
                                      : AppColors.pink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('New password',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          UnderlineField(
                            controller: _passCtrl,
                            hint: 'At least 6 characters',
                            trailingIcon: _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            obscure: _obscure,
                            validator: Validators.password,
                            onTrailingTap: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          const SizedBox(height: 16),
                          UnderlineField(
                            controller: _confirmCtrl,
                            hint: 'Confirm new password',
                            trailingIcon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (v) =>
                                Validators.confirmPassword(v, _passCtrl.text),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 13),
                                textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 24),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: GradientButton(
                              label: 'Update password',
                              icon: Icons.check_rounded,
                              loading: _loading,
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
