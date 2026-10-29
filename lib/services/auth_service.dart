import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Current Supabase auth user (or null if signed out).
  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Whether the current user's email is verified.
  bool get isEmailVerified {
    final user = currentUser;
    if (user == null) return false;
    return user.emailConfirmedAt != null;
  }

  /// Validate that the email belongs to the university.
  static bool isUniversityEmail(String email) {
    final lower = email.toLowerCase().trim();
    return lower.endsWith('@${AppConstants.universityEmailDomain}');
  }

  /// Sign up a new student with university email.
  /// Returns the created AppUser. Throws a readable error message on failure.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    String? department,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!isUniversityEmail(cleanEmail)) {
      throw 'Please use your university email '
          '(@${AppConstants.universityEmailDomain})';
    }

    try {
      final res = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'name': name,
          'student_id': studentId,
          if (department != null) 'department': department,
        },
      );

      final user = res.user;
      if (user == null) {
        throw 'Could not create account. Please try again.';
      }

      // The profile row is auto-created by a Postgres trigger
      // (on_auth_user_created → handle_new_user). We attempt an upsert here
      // as a fallback, but ignore any failure (e.g., if RLS blocks because
      // the user has no session yet — common when "Confirm email" is ON).
      try {
        await _client
            .from(AppConstants.usersTable)
            .upsert({
              'id': user.id,
              'email': cleanEmail,
              'name': name,
              'student_id': studentId,
              'department': department,
            }, onConflict: 'id');
      } catch (_) {
        // Trigger will have created it. Safe to ignore.
      }

      return AppUser(
        uid: user.id,
        email: cleanEmail,
        name: name,
        studentId: studentId,
        department: department,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw _readableAuthError(e);
    }
  }

  /// Sign in with email + password.
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!isUniversityEmail(cleanEmail)) {
      throw 'Please use your university email '
          '(@${AppConstants.universityEmailDomain})';
    }

    try {
      final res = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      final user = res.user;
      if (user == null) throw 'Sign in failed. Please try again.';
      return user;
    } on AuthException catch (e) {
      throw _readableAuthError(e);
    }
  }

  /// Send a password reset OTP code to the user's email.
  /// Supabase will email an 8-character OTP that we verify with [verifyPasswordResetOtp].
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!isUniversityEmail(cleanEmail)) {
      throw 'Please use your university email';
    }
    try {
      // No redirectTo → forces OTP-only flow (no magic link).
      await _client.auth.resetPasswordForEmail(cleanEmail);
    } on AuthException catch (e) {
      throw _readableAuthError(e);
    }
  }

  /// Verify the signup OTP code (sent to email after signUp).
  /// On success, the user is signed in and email is marked verified.
  Future<void> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
        token: token.trim(),
      );
      if (res.user == null) {
        throw 'Invalid or expired code. Please try again.';
      }
    } on AuthException catch (e) {
      throw _readableAuthError(e);
    }
  }

  /// Verify a password recovery OTP code. On success the user has a session
  /// and can call [updatePassword] to set their new password.
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email.trim().toLowerCase(),
        token: token.trim(),
      );
      if (res.user == null) {
        throw 'Invalid or expired code. Please try again.';
      }
    } on AuthException catch (e) {
      throw _readableAuthError(e);
    }
  }

  /// Update the password of the currently signed-in user.
  /// Must be called after [verifyPasswordResetOtp] succeeds.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _readableAuthError(e);
    }
  }

  /// Resend the signup verification OTP.
  Future<void> resendVerification() async {
    final user = currentUser;
    if (user == null || user.email == null) return;
    if (user.emailConfirmedAt != null) return;
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
    } on AuthException catch (e) {
      throw _readableAuthError(e);
    }
  }

  /// Resend the signup verification OTP to an explicit email
  /// (used when the user is on the verify screen but not yet signed-in,
  /// e.g., they opened the app fresh after closing it post-signup).
  Future<void> resendSignupOtp(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );
    } on AuthException catch (e) {
      throw _readableAuthError(e);
    }
  }

  /// Refresh the session — useful for checking if email got verified.
  Future<void> refreshSession() async {
    try {
      await _client.auth.refreshSession();
    } catch (_) {
      // ignore — session may not exist
    }
  }

  /// Fetch the profile row for the current user.
  Future<AppUser?> fetchCurrentUserDoc() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from(AppConstants.usersTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) return null;
      return AppUser.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  String _readableAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('user already registered')) {
      return 'This email is already registered. Try signing in instead.';
    }
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Email or password is incorrect.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (msg.contains('token has expired') || msg.contains('expired')) {
      return 'The code has expired. Please request a new one.';
    }
    if (msg.contains('invalid token') || msg.contains('otp') && msg.contains('invalid')) {
      return 'Invalid code. Please check and try again.';
    }
    if (msg.contains('password') && msg.contains('6')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (msg.contains('network')) {
      return 'Network error. Check your internet connection.';
    }
    return e.message;
  }
}
