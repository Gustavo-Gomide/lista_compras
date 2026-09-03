import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/customization/customization_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/windows_protocol_registrar.dart';
import 'providers/auth_provider.dart';
import 'providers/lists_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/update_password_screen.dart';
import 'screens/lists/lists_home_screen.dart';

/// Ponto de entrada principal do aplicativo.
Future<void> main() async {
  // Garante que a ligação dos widgets do Flutter esteja inicializada antes de executar métodos assíncronos.
  WidgetsFlutterBinding.ensureInitialized();

  // Registra o protocolo customizado no Windows (para deep links etc).
  registerWindowsProtocol();

  // Inicializa a conexão com o banco de dados Supabase usando as chaves de configuração.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // Inicializa o provedor de customização (tema, tamanho de fonte) e carrega as preferências salvas.
  final customization = CustomizationProvider();
  await customization.load();

  // Inicia a aplicação passando o provedor de customização previamente carregado.
  runApp(MyApp(customization: customization));
}

/// O widget raiz da aplicação, onde os provedores de estado e as configurações de tema são definidos.
class MyApp extends StatelessWidget {
  final CustomizationProvider customization;
  
  const MyApp({super.key, required this.customization});

  @override
  Widget build(BuildContext context) {
    // MultiProvider permite que a gente injete diversas classes de estado (providers)
    // na árvore de widgets. Assim, qualquer tela abaixo pode escutá-las.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: customization),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ListsProvider()),
      ],
      // O Consumer observa o CustomizationProvider para atualizar a interface
      // sempre que o usuário muda o tema ou o tamanho da fonte.
      child: Consumer<CustomizationProvider>(
        builder: (context, custom, _) {
          return MaterialApp(
            title: 'Lista de Compras',
            debugShowCheckedModeBanner: false, // Esconde a faixa de debug.
            theme: AppTheme.build(custom.model), // Constrói o tema baseado na customização do usuário.
            
            // O builder do MaterialApp nos permite injetar widgets ou sobrepor configurações
            // globalmente. Aqui usamos para aplicar o multiplicador de escala da fonte (`fontScale`).
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(custom.model.fontScale)),
                // Envolvemos o app inteiro com o ShowCaseWidget para suportar os tutoriais passo-a-passo.
                // ignore: deprecated_member_use
                child: ShowCaseWidget(
                  builder: (context) => child!,
                ),
              );
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Widget que atua como uma porta giratória (Gate).
/// Ele verifica o estado da autenticação e decide qual tela mostrar ao usuário.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta mudanças no provedor de autenticação.
    final auth = context.watch<AuthProvider>();
    
    // Se o usuário solicitou recuperação de senha, envia para a tela de criar nova senha.
    if (auth.passwordRecovery) return const UpdatePasswordScreen();
    
    // Caso esteja logado, envia para a tela principal (Suas listas). Se não, volta para o Login.
    return auth.isLoggedIn ? const ListsHomeScreen() : const LoginScreen();
  }
}
