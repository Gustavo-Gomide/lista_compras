class SupabaseConfig {
  // Substitua pelos valores do seu projeto (Supabase > Settings > API)
  // Você pode manter os valores aqui ou passar via --dart-define ao rodar/buildar:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vxkysyyjloifbkydswtb.supabase.co',
  );

  // A Supabase substituiu a "anon key" pela "publishable key" (prefixo sb_publishable_...).
  // Pegue em Settings > API Keys > Publishable key no painel do seu projeto.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_oCXPPTmwajp4_QANVKmIHw_l4Kstop-',
  );

  // URL de retorno usada no login com Google (mobile/desktop).
  // Precisa ser cadastrada em Supabase > Authentication > URL Configuration
  // e no seu app (AndroidManifest / Info.plist). Veja o README.
  static const String oauthRedirectUri =
      'io.supabase.listacompras://login-callback/';

  // ── Google Sign-In nativo (Android / iOS / macOS) ──────────────────────
  // O Web Client ID é obrigatório: é ele que o google_sign_in usa como
  // "serverClientId" para gerar o idToken verificável pelo backend.
  // Crie em Google Cloud Console > APIs & Services > Credentials >
  //   OAuth 2.0 Client IDs > tipo "Web application".
  // Também é o mesmo ID que você cadastra no painel do Supabase em
  //   Authentication > Providers > Google > Client ID (web).
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '281862441973-6d9jmr6sqnnktfunb3cggmngicuivqhj.apps.googleusercontent.com',
  );

  // O iOS Client ID é necessário apenas no iOS/macOS.
  // Crie em Google Cloud Console > OAuth 2.0 Client IDs > tipo "iOS".
  // O reversed client ID (ex: com.googleusercontent.apps.XXXX) deve ser
  // adicionado como URL scheme no Info.plist.
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '281862441973-kb1n7gipbgkt4utb5a392699dobbvojj.apps.googleusercontent.com',
  );

  static const String androidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '281862441973-6d9jmr6sqnnktfunb3cggmngicuivqhj.apps.googleusercontent.com',
  );
}
