import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:receitas_do_guaxininho/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Testes de Fluxo de Criação de Receita', () {
    testWidgets(
        'Usuário logado deve conseguir criar e ver uma nova receita',
            (WidgetTester tester) async {
          // 1. INICIAR O APP E FAZER LOGIN
          app.main();
          await tester.pumpAndSettle();

          const testEmail = 'benjota7100@gmail.com';
          const testPassword = '98008937';

          await tester.enterText(
              find.widgetWithText(TextFormField, 'Email'), testEmail);
          await tester.enterText(
              find.widgetWithText(TextFormField, 'Senha'), testPassword);
          await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
          await tester.pumpAndSettle(const Duration(seconds: 10));

          // 2. NAVEGAR PARA A TELA DE CRIAÇÃO
          final addButton = find.byIcon(Icons.add);
          expect(addButton, findsOneWidget);
          await tester.tap(addButton);
          await tester.pumpAndSettle();

          expect(find.text('Nova Receita'), findsOneWidget);

          // 3. PREENCHER O FORMULÁRIO DE FORMA ROBUSTA
          final recipeName =
              'Bolo de Teste Automatizado ${DateTime.now().millisecondsSinceEpoch}';

          await tester.enterText(find.widgetWithText(TextFormField, 'Nome da Receita'), recipeName);
          await tester.enterText(find.widgetWithText(TextFormField, 'Descrição'), 'Descrição de teste.');
          await tester.enterText(find.widgetWithText(TextFormField, 'Ingredientes'), 'Ingrediente 1\nIngrediente 2');
          await tester.enterText(find.widgetWithText(TextFormField, 'Modo de Preparo'), 'Passo 1\nPasso 2');
          await tester.enterText(find.widgetWithText(TextFormField, 'Tempo (min)'), '45');
          await tester.enterText(find.widgetWithText(TextFormField, 'Porções'), '8');

          // Toca no título da AppBar para garantir que o foco saia do campo de texto e o teclado feche.
          await tester.tap(find.text('Nova Receita'));
          await tester.pumpAndSettle(const Duration(milliseconds: 500)); // Espera a animação do teclado

          final categoryDropdown = find.byType(DropdownButtonFormField<String>);
          await tester.ensureVisible(categoryDropdown);
          await tester.pumpAndSettle();

          await tester.tap(categoryDropdown);
          await tester.pumpAndSettle(); // Espera o menu abrir

          // Encontra e toca na opção desejada
          final categoryOption = find.text('Bolos e Tortas').last;
          await tester.tap(categoryOption);
          await tester.pumpAndSettle(); // Espera o menu fechar

          // 4. SUBMETER O FORMULÁRIO
          final saveButton = find.widgetWithText(ElevatedButton, 'Salvar Receita');
          await tester.ensureVisible(saveButton);
          await tester.pumpAndSettle();
          await tester.tap(saveButton);

          // 5. VERIFICAR O RESULTADO
          await tester.pumpAndSettle(const Duration(seconds: 5));

          expect(addButton, findsOneWidget);

          final newRecipeCard = find.text(recipeName);

          // Especificamos qual widget rolável usar.
          // Neste caso, a lista principal, que podemos identificar
          // por ser a ancestral do carrossel 'Populares'.
          final mainListFinder = find.ancestor(
                of: find.text('Populares'),
                matching: find.byType(Scrollable),
          );

          await tester.scrollUntilVisible(
                newRecipeCard,
                100.0,
                scrollable: mainListFinder,
          );

          expect(newRecipeCard, findsOneWidget,
              reason: 'A receita recém-criada não foi encontrada na HomePage.');
            });
  });
}