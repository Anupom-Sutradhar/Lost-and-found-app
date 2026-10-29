import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/underline_field.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _deptCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cleanEmail = _emailCtrl.text.trim().toLowerCase();
      await context.read<AuthProvider>().service.signUp(
            email: cleanEmail,
            password: _passCtrl.text,
            name: _nameCtrl.text.trim(),
            studentId: _idCtrl.text.trim(),
            department:
                _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(email: cleanEmail)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString(),
              style: const TextStyle(color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AuthCard(
                    isLogin: false,
                    onTabChanged: (login) {
                      if (login) _goLogin();
                    },
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          UnderlineField(
                            controller: _nameCtrl,
                            hint: 'Full name',
                            trailingIcon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                Validators.required(v, field: 'Full name'),
                          ),
                          const SizedBox(height: 16),
                          UnderlineField(
                            controller: _idCtrl,
                            hint: 'Student ID',
                            trailingIcon: Icons.badge_outlined,
                            validator: Validators.studentId,
                          ),
                          const SizedBox(height: 16),
                          UnderlineField(
                            controller: _deptCtrl,
                            hint: 'Department (optional)',
                            trailingIcon: Icons.school_outlined,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          UnderlineField(
                            controller: _emailCtrl,
                            hint: 'University email',
                            trailingIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.universityEmail,
                          ),
                          const SizedBox(height: 16),
                          UnderlineField(
                            controller: _passCtrl,
                            hint: 'Password',
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
                            hint: 'Confirm password',
                            trailingIcon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _signUp(),
                            validator: (v) =>
                                Validators.confirmPassword(v, _passCtrl.text),
                          ),
                          const SizedBox(height: 28),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GradientButton(
                              label: 'Create account',
                              loading: _loading,
                              onPressed: _signUp,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.inter(
                                    color: AppColors.slate, fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: _goLogin,
                                child: Text(
                                  'LOGIN',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.pink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
