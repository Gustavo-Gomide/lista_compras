import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:win32_registry/win32_registry.dart';

/// Registra o protocolo (deep link) no Registro do Windows (HKEY_CURRENT_USER)
/// para que o navegador consiga redirecionar de volta para o app após o login.
void registerWindowsProtocol() {
  if (kIsWeb || !Platform.isWindows) return;
  
  try {
    const scheme = 'io.supabase.listacompras';
    final appPath = Platform.resolvedExecutable;
    
    final classesKey = Registry.currentUser.createKey('Software\\Classes\\$scheme');
    
    classesKey.createValue(const RegistryValue.string(
      '',
      'URL:ListaCompras Protocol',
    ));
    classesKey.createValue(const RegistryValue.string(
      'URL Protocol',
      '',
    ));
    
    final commandKey = classesKey.createKey('shell\\open\\command');
    commandKey.createValue(RegistryValue.string(
      '',
      '"$appPath" "%1"',
    ));
    
    classesKey.close();
  } catch (e) {
    debugPrint('Erro ao registrar protocolo no Windows: $e');
  }
}
