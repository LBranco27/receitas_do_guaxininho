import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receitas_do_guaxininho/features/recipes/view/widgets/recipe_card.dart';

Widget makeTestableWidget({required Widget child}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
            width: 300,
            height: 300,
            child: child
        ),
      ),
    ),
  );
}

void main() {
  group('Testes do Widget RecipeCard', () {
    const String testTitle = 'Pão de Queijo';
    const String testSubtitle = 'Salgados • 45 min';
    const String testImagePath =
        'https://placehold.co/600x400/yellow/black?text=Pão+de+Queijo';

    testWidgets(
        'Deve exibir o título, subtítulo e ícone de favorito corretamente',
            (WidgetTester tester) async {
          // 1. Arrange: "Infla" o widget com estado de favorito 'true'.
          await tester.pumpWidget(makeTestableWidget(
            child: RecipeCard(
              title: testTitle,
              subtitle: testSubtitle,
              imagePath: testImagePath,
              favorite: true, // Testando com o estado de favorito ativado
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ));

          // 2. Act & Assert: Procura por widgets específicos na árvore.

          // Procura pelo título e subtítulo.
          expect(find.text(testTitle), findsOneWidget);
          expect(find.text(testSubtitle), findsOneWidget);

          // Verifica se a imagem está sendo exibida.
          expect(find.byType(Image), findsOneWidget);

          // Verifica se o ícone de favorito preenchido está visível
          // e o de borda não está.
          expect(find.byIcon(Icons.favorite), findsOneWidget);
          expect(find.byIcon(Icons.favorite_border), findsNothing);
        });

    testWidgets('Deve chamar a função onTap quando o card for pressionado',
            (WidgetTester tester) async {
          bool tapped = false;

          // 1. Arrange: Prepara o widget com uma função de callback para o tap.
          await tester.pumpWidget(makeTestableWidget(
            child: RecipeCard(
              title: testTitle,
              subtitle: testSubtitle,
              onTap: () {
                tapped = true; // Muda a variável para true quando o callback é chamado.
              },
              onFavoriteToggle: () {},
            ),
          ));

          // 2. Act: Simula um toque (tap) no widget RecipeCard.
          await tester.tap(find.byType(RecipeCard));
          await tester.pump();

          // 3. Assert: Verifica se a nossa variável de controle foi alterada.
          expect(tapped, isTrue);
        });

    testWidgets(
        'Deve chamar onFavoriteToggle quando o ícone de favorito for pressionado',
            (WidgetTester tester) async {
          bool favoriteToggled = false;

          // 1. Arrange: Prepara o widget com estado de favorito 'false'.
          await tester.pumpWidget(makeTestableWidget(
            child: RecipeCard(
              title: testTitle,
              subtitle: testSubtitle,
              favorite: false,
              onTap: () {},
              onFavoriteToggle: () {
                favoriteToggled = true;
              },
            ),
          ));

          // 2. Act: Encontra o ícone de favorito (que deve ser o de borda) e simula um toque.
          final favoriteIconFinder = find.byIcon(Icons.favorite_border);
          expect(favoriteIconFinder, findsOneWidget);

          await tester.tap(favoriteIconFinder);
          await tester.pump();

          // 3. Assert: Verifica se o callback de toggle foi chamado.
          expect(favoriteToggled, isTrue);
        });
  });
}
