import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:network_image_mock/network_image_mock.dart';

import 'package:receitas_do_guaxininho/features/recipes/view/widgets/recipe_card.dart';



void main() {

  group('RecipeCard Widget Tests', () {

    testWidgets('Deve exibir imagem, textos e a cor correta para o ícone de favorito',

            (WidgetTester tester) async {

          mockNetworkImagesFor(() async {

            late final Color expectedFavoriteColor;



            await tester.pumpWidget(

              MaterialApp(

                theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),

                home: Builder(builder: (context) {

                  expectedFavoriteColor = Theme.of(context).colorScheme.primary;

                  return Scaffold(

                    body: RecipeCard(

                      title: 'Bolo de Fubá',

                      subtitle: '60 min • 8 porções',

                      imagePath: 'https://exemplo.com/bolo.jpg',

                      favorite: true,

                      onTap: () {},

                      onFavoriteToggle: () {},

                    ),

                  );

                }),

              ),

            );



            expect(find.text('Bolo de Fubá'), findsOneWidget);

            expect(find.text('60 min • 8 porções'), findsOneWidget);

            expect(find.byType(Image), findsOneWidget);



            final favoriteIcon = tester.widget<Icon>(find.byIcon(Icons.favorite));

            expect(favoriteIcon.color, expectedFavoriteColor);

          });

        });



    testWidgets('Deve chamar os callbacks de onTap e onFavoriteToggle', (WidgetTester tester) async {

      bool cardWasTapped = false;

      bool favoriteWasToggled = false;



      await tester.pumpWidget(

        MaterialApp(

          home: Scaffold(

            body: RecipeCard(

              title: 'Teste de Interação',

              subtitle: 'subtitle',

              favorite: false,

              onTap: () => cardWasTapped = true,

              onFavoriteToggle: () => favoriteWasToggled = true,

            ),

          ),

        ),

      );



      await tester.tap(find.byType(RecipeCard));

      await tester.pump();



      expect(cardWasTapped, isTrue);



      await tester.tap(find.byIcon(Icons.favorite_border));

      await tester.pump();



      expect(favoriteWasToggled, isTrue);

    });

  });

}