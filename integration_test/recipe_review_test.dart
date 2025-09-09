import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:receitas_do_guaxininho/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recipe Review Flow', () {
    const String targetRecipeName = '10kg de amendoim torrado';
    const String reviewText = 'hummmm comi tudo e gostei muito. Muito bom o amendoim.';
    const double reviewRating = 4.0;

    testWidgets('''
      Attempts to add a review for '$targetRecipeName'.
      - If logged in: Submits a 4-star review with text and verifies it.
      - If not logged in: Verifies the "login required" message for reviews.
    ''', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final recipeCardFinder = find.text(targetRecipeName);
      await tester.scrollUntilVisible(recipeCardFinder, 50.0, scrollable: find.byType(Scrollable).first);
      expect(recipeCardFinder, findsOneWidget, reason: "Recipe '$targetRecipeName' should be found on the list.");
      
      await tester.tap(recipeCardFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final reviewsSectionTitleFinder = find.text('Avaliações');
      await tester.scrollUntilVisible(reviewsSectionTitleFinder, 100.0, scrollable: find.byType(Scrollable).first);
      expect(reviewsSectionTitleFinder, findsOneWidget, reason: "Reviews section title 'Avaliações' should be visible.");

      final reviewInputFieldFinder = find.widgetWithText(TextField, 'Escreva sua avaliação (opcional)...');
      final loginToReviewMessageFinder = find.text('Você precisa estar logado para avaliar.');

      // Check if the review input field is present.
      // tester.any() checks if the widget is in the tree (even if offstage).
      if (tester.any(reviewInputFieldFinder)) {
        print("INFO: Review input section found. Proceeding to add a review.");

        // Ensure the input field is visible before interacting
        await tester.scrollUntilVisible(reviewInputFieldFinder, 50.0, scrollable: find.byType(Scrollable).first);

        final starIconButtons = find.descendant(
          // Scope to the review input card. This predicate finds the Card widget
          // that contains the star rating IconButtons.
          of: find.byWidgetPredicate(
            (widget) => widget is Card && widget.elevation == 2 && tester.any(find.descendant(of: find.byWidget(widget), matching: find.widgetWithText(TextField, 'Escreva sua avaliação (opcional)...'))),
          ),
          matching: find.byType(IconButton),
        );
        expect(starIconButtons, findsNWidgets(5), reason: "Should find 5 star IconButtons for rating input.");
        await tester.tap(starIconButtons.at(reviewRating.toInt() - 1));
        await tester.pumpAndSettle();

        await tester.enterText(reviewInputFieldFinder, reviewText);
        await tester.pump();

        final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Enviar');
        final updateButtonFinder = find.widgetWithText(ElevatedButton, 'Atualizar');
        
        Finder actualSubmitButtonFinder;
        if (tester.any(submitButtonFinder)) {
            actualSubmitButtonFinder = submitButtonFinder;
        } else if (tester.any(updateButtonFinder)) {
            actualSubmitButtonFinder = updateButtonFinder;
            print("INFO: Review form is in 'Update' mode.");
        } else {
            throw Exception("Could not find 'Enviar' or 'Atualizar' button for review submission.");
        }
        
        // Ensure submit button is visible
        await tester.scrollUntilVisible(actualSubmitButtonFinder, 50.0, scrollable: find.byType(Scrollable).first);
        expect(actualSubmitButtonFinder, findsOneWidget);
        await tester.tap(actualSubmitButtonFinder);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final submittedReviewTextFinder = find.text(reviewText);
        await tester.scrollUntilVisible(submittedReviewTextFinder.last, 50.0, scrollable: find.byType(Scrollable).last);
        expect(submittedReviewTextFinder.last, findsOneWidget, reason: "Submitted review text '$reviewText' should be visible.");

        final reviewItemFinder = find.ancestor(
          of: submittedReviewTextFinder,
          matching: find.byWidgetPredicate(
            (widget) => widget is Card && widget.elevation == 1.5 // Assuming _ReviewItem uses Card with elevation 1.5
          )
        );
        expect(reviewItemFinder, findsOneWidget, reason: "The card for the submitted review item should be found + the review text input.");

        final starsInReviewItemFinder = find.descendant(
          of: reviewItemFinder,
          matching: find.byIcon(Icons.star),
        );
        expect(starsInReviewItemFinder, findsNWidgets(reviewRating.floor()), reason: "Should find ${reviewRating.floor()} full stars in the submitted review.");
        
        if (reviewRating - reviewRating.floor() >= 0.5) {
            final halfStarInReviewItemFinder = find.descendant(
              of: reviewItemFinder,
              matching: find.byIcon(Icons.star_half),
            );
            expect(halfStarInReviewItemFinder, findsOneWidget, reason: "Should find one half star if rating is X.5.");
        }
      } else if (tester.any(loginToReviewMessageFinder)) {
        print("INFO: 'Você precisa estar logado para avaliar.' message found. Test verifies this state.");
        await tester.scrollUntilVisible(loginToReviewMessageFinder, 50.0, scrollable: find.byType(Scrollable).first);
        expect(loginToReviewMessageFinder, findsOneWidget);
      } else {
        fail('Expected to find either the review input field or the "login required" message, but found neither.');
      }
    });
  });
}
