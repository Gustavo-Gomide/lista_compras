import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// true quando o usuário chegou ao app pelo link de "esqueci a senha"
  /// e precisa definir uma nova senha antes de continuar.
  bool passwordRecovery = false;

  AuthProvider() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((state) {
      _user = state.session?.user;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        passwordRecovery = true;
      }
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _authService.signInWithEmail(email, password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao entrar: $e';
    }
  }

  Future<String?> signUp(String email, String password, String displayName) async {
    try {
      await _authService.signUpWithEmail(email, password, displayName: displayName);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao cadastrar: $e';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      return null;
    } catch (e) {
      return 'Erro ao entrar com Google: $e';
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _authService.resetPassword(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao enviar e-mail de recuperação: $e';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
      passwordRecovery = false;
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao atualizar senha: $e';
    }
  }

  void cancelPasswordRecovery() {
    passwordRecovery = false;
    notifyListeners();
  }

  bool get hasGoogleLinked => _authService.hasGoogleLinked;

  Future<String?> updateDisplayName(String name) async {
    try {
      await _authService.updateDisplayName(name);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Erro ao atualizar nome: $e';
    }
  }

  Future<String?> updateEmail(String email) async {
    try {
      await _authService.updateEmail(email);
      return null;
    } catch (e) {
      return 'Erro ao atualizar e-mail: $e';
    }
  }

  Future<String?> linkGoogle() async {
    try {
      await _authService.linkGoogle();
      return null;
    } catch (e) {
      return 'Erro ao vincular Google: $e';
    }
  }

  Future<String?> unlinkGoogle() async {
    try {
      await _authService.unlinkGoogle();
      notifyListeners();
      return null;
    } catch (e) {
      return 'Erro ao desvincular Google: $e';
    }
  }
}
