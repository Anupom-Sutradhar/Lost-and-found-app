import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, signedOut, unverified, signedIn }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _sub;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _appUser;
  User? _supabaseUser;

  AuthStatus get status => _status;
  AppUser? get appUser => _appUser;
  User? get supabaseUser => _supabaseUser;
  AuthService get service => _authService;

  AuthProvider() {
    // Initialise from current session, then listen for changes.
    _initFromCurrentSession();
    _sub = _authService.authStateChanges.listen((state) {
      _onAuthChanged(state.session?.user);
    });
  }

  Future<void> _initFromCurrentSession() async {
    final user = _authService.currentUser;
    await _onAuthChanged(user);
  }

  Future<void> _onAuthChanged(User? user) async {
    _supabaseUser = user;
    if (user == null) {
      _status = AuthStatus.signedOut;
      _appUser = null;
    } else if (user.emailConfirmedAt == null) {
      _status = AuthStatus.unverified;
      _appUser = null;
    } else {
      _appUser = await _authService.fetchCurrentUserDoc();
      _status = AuthStatus.signedIn;
    }
    notifyListeners();
  }

  /// Force a refresh (e.g., user clicked "I verified — continue").
  Future<void> refresh() async {
    await _authService.refreshSession();
    await _onAuthChanged(_authService.currentUser);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void updateLocalUser(AppUser updated) {
    _appUser = updated;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
