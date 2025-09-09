import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:receitas_do_guaxininho/main.dart' as app;
import 'package:receitas_do_guaxininho/features/recipes/view/widgets/recipe_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Testes de Integração do App de Receitas', () {
    testWidgets('Fluxo de Login: deve autenticar o usuário com sucesso',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle();

          // IMPORTANTE: Não pode apagar este usuário lá no Supabase.
          const testEmail = 'teste@mail.com';
          const testPassword = 'teste123';

          final textFields = find.byType(TextFormField);
          expect(textFields, findsNWidgets(2), reason: 'Deveriam haver dois campos de texto (email e senha) na tela de login.');

          await tester.enterText(textFields.first, testEmail);
          await tester.enterText(textFields.last, testPassword);

          await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));

          await tester.pumpAndSettle(const Duration(seconds: 10));

          expect(find.byType(RecipeCard, skipOffstage: false), findsWidgets,
              reason: 'A lista de receitas (RecipeCard) deveria ser exibida após o login.');

          // IMPORTANTE: Não pode mudar o nome do usuário "Teste da Silva".
          const userName = 'Teste da Silva';
          expect(find.text('Olá, $userName'), findsOneWidget, reason: 'O título da AppBar "Olá, $userName" não foi encontrado. Verifique o nome do seu usuário de teste.');
        });
  });
}