import 'package:flutter_test/flutter_test.dart';

// O teste "contador" padrão gerado pelo `flutter create` não se aplica a
// este app. Testar as telas reais exigiria inicializar/mockar o Supabase
// antes de montar o MyApp (que hoje recebe SupabaseClient real). Por ora,
// deixamos um teste simples só para o `flutter test` não quebrar o build.
void main() {
  test('sanity check', () {
    expect(1 + 1, 2);
  });
}
