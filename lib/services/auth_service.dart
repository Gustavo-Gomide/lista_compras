import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Retorna true nas plataformas onde o pacote google_sign_in funciona
  /// (Android, iOS, macOS). Nas demais (Windows, Linux, Web) usamos o
  /// fluxo OAuth via navegador externo.
  bool get _useNativeGoogle {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, {String? displayName}) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );
  }

  /// Envia o e-mail de recuperação de senha. O link do e-mail abre o app
  /// (mobile/desktop com deep link configurado) ou a versão web, e dispara
  /// o evento AuthChangeEvent.passwordRecovery, tratado no AuthProvider.
  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? Uri.base.origin : SupabaseConfig.oauthRedirectUri,
    );
  }

  /// Usado depois que o usuário chega pelo link de recuperação de senha.
  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> updateDisplayName(String name) async {
    await _client.auth.updateUser(UserAttributes(data: {'full_name': name}));
    final uid = currentUser?.id;
    if (uid != null) {
      await _client.from('profiles').update({'display_name': name}).eq('id', uid);
    }
  }

  /// Por padrão o Supabase envia e-mail de confirmação para o endereço
  /// novo (e opcionalmente para o antigo) antes de efetivar a troca.
  Future<void> updateEmail(String email) {
    return _client.auth.updateUser(UserAttributes(email: email));
  }

  bool get hasGoogleLinked {
    final identities = currentUser?.identities ?? [];
    return identities.any((i) => i.provider == 'google');
  }

  Future<void> linkGoogle() {
    return _client.auth.linkIdentity(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : SupabaseConfig.oauthRedirectUri,
    );
  }

  Future<void> unlinkGoogle() async {
    final identities = currentUser?.identities ?? [];
    final google = identities.where((i) => i.provider == 'google');
    if (google.isNotEmpty) {
      await _client.auth.unlinkIdentity(google.first);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Login com Google — escolhe automaticamente o melhor fluxo
  // ═══════════════════════════════════════════════════════════════════════

  /// Login com Google.
  ///
  /// **Android / iOS / macOS**: usa o popup nativo do Google (pacote
  /// `google_sign_in`) para obter um `idToken`, e autentica com
  /// `signInWithIdToken` — o usuário não sai do app.
  ///
  /// **Windows / Linux / Web**: usa `signInWithOAuth` que abre o navegador
  /// do sistema para o fluxo OAuth padrão do Supabase.
  Future<AuthResponse?> signInWithGoogle() async {
    if (_useNativeGoogle) {
      return _signInWithGoogleNative();
    }
    return _signInWithGoogleOAuth();
  }

  /// Fluxo nativo via google_sign_in → signInWithIdToken.
  Future<AuthResponse> _signInWithGoogleNative() async {
    final googleSignIn = GoogleSignIn(
      clientId: defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS
          ? SupabaseConfig.iosClientId
          : null,
      serverClientId: SupabaseConfig.webClientId,
      scopes: ['email'],
    );

    await googleSignIn.signOut();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Login cancelado pelo usuário.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException(
        'Não foi possível obter o token de autenticação do Google. '
        'Verifique se o Web Client ID está configurado corretamente.',
      );
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Fluxo OAuth via navegador externo (Windows, Linux, Web).
  Future<AuthResponse?> _signInWithGoogleOAuth() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : SupabaseConfig.oauthRedirectUri,
      authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      queryParams: {'prompt': 'select_account'},
    );
    // signInWithOAuth retorna void; a sessão chega via deep link / redirect
    // e é capturada pelo listener onAuthStateChange no AuthProvider.
    return null;
  }

  Future<void> signOut() async {
    // Desconectar do Google nativo para permitir trocar de conta.
    if (_useNativeGoogle) {
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
        }
      } catch (_) {
        // Ignora — pode não estar logado nativamente.
      }
    }
    await _client.auth.signOut();
  }
}
