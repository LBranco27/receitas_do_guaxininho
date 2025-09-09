import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:receitas_do_guaxininho/main.dart' as app; // Import your app's main entry point

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recipe Review Flow', () {
    const String targetRecipeName = '10kg de amendoim torrado'; // Adjust if needed
    const String reviewText = 'hummmm comi tudo e gostei muito. Muito bom o amendoim.';
    const double reviewRating = 5.0;

    testWidgets('''
      Attempts to add a review for '$targetRecipeName'.
      - If logged in: Submits a 5-star review with text and verifies it.
      - If not logged in: Verifies the "login required" message for reviews.
    ''', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to the target recipe's detail page
      //    We'll assume recipes are listed and we can find one by its name.
      //    This might involve scrolling if the list is long.
      final recipeCardFinder = find.text(targetRecipeName); // More robust with Keys

      // Scroll until the recipe card is visible (if necessary)
      // This is a basic scroll; for long lists, more sophisticated scrolling might be needed.
      await tester.scrollUntilVisible(recipeCardFinder, 50.0, scrollable: find.byType(Scrollable).first);
      expect(recipeCardFinder, findsOneWidget, reason: "Recipe '$targetRecipeName' should be found on the list.");
      
      await tester.tap(recipeCardFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Wait for navigation and page load

      // Now on RecipeDetailPage for "Martini de Morango"

      // 2. Find the Reviews section (scrolling if necessary)
      final reviewsSectionTitleFinder = find.text('Avaliações');
      await tester.scrollUntilVisible(reviewsSectionTitleFinder, 100.0, scrollable: find.byType(Scrollable).first);
      expect(reviewsSectionTitleFinder, findsOneWidget, reason: "Reviews section title 'Avaliações' should be visible.");

      // 3. Check if the review input section is available or if "login required" is shown
      final reviewInputFieldFinder = find.widgetWithText(TextField, 'Escreva sua avaliação (opcional)...');
      final loginToReviewMessageFinder = find.text('Você precisa estar logado para avaliar.');

      if (await tester.widget<dynamic>(reviewInputFieldFinder, skipOffstage: false).then((_) => true).catchError((_) => false)) {
        // --- User IS likely logged in: Review input section is present ---
        print("INFO: Review input section found. Proceeding to add a review.");

        // Tap the stars to give a rating (e.g., 4th star for 4.0)
        // Assuming stars are IconButton with Icons.star_border or Icons.star
        // The RatingStars input widget for reviews creates 5 IconButtons.
        // Tapping the 4th star (index 3)
        final starIconButtons = find.descendant(
          of: find.byType(Card).filter((widget) => widget.elevation == 2), // Try to scope to review input card
          matching: find.byType(IconButton),
        );
        expect(starIconButtons, findsNWidgets(5), reason: "Should find 5 star IconButtons for rating input.");
        await tester.tap(starIconButtons.at(reviewRating.toInt() - 1)); // Tap 4th star (index 3)
        await tester.pumpAndSettle();

        // Enter review text
        await tester.enterText(reviewInputFieldFinder, reviewText);
        await tester.pump();

        // Submit the review
        final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Enviar'); // Or 'Atualizar' if editing
         // Check for 'Atualizar' as well if an old review might exist
        final updateButtonFinder = find.widgetWithText(ElevatedButton, 'Atualizar');
        
        Finder actualSubmitButtonFinder;
        if (await tester.widget<dynamic>(submitButtonFinder).then((_) => true).catchError((_) => false)) {
            actualSubmitButtonFinder = submitButtonFinder;
        } else if (await tester.widget<dynamic>(updateButtonFinder).then((_) => true).catchError((_) => false)) {
            actualSubmitButtonFinder = updateButtonFinder;
            print("INFO: Review form is in 'Update' mode.");
        } else {
            throw Exception("Could not find 'Enviar' or 'Atualizar' button for review submission.");
        }
        
        expect(actualSubmitButtonFinder, findsOneWidget);
        await tester.tap(actualSubmitButtonFinder);
        await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for submission and UI update

        // Verify the review appears in the list
        // Scroll to ensure the new review is visible if the list is long
        final submittedReviewTextFinder = find.text(reviewText);
        await tester.scrollUntilVisible(submittedReviewTextFinder, 50.0, scrollable: find.byType(Scrollable).first);
        expect(submittedReviewTextFinder, findsOneWidget, reason: "Submitted review text '$reviewText' should be visible.");

        // Verify the stars next to the submitted review
        // This is a bit more complex as stars are individual Icon widgets.
        // We need to find the _ReviewItem that contains our text, then find stars within it.
        final reviewItemFinder = find.ancestor(
          of: submittedReviewTextFinder,
          matching: find.byType(Card).filter((widget) => widget.elevation == 1.5), // Assuming _ReviewItem uses Card with elevation 1.5
        );
        expect(reviewItemFinder, findsOneWidget, reason: "The card for the submitted review item should be found.");

        final starsInReviewItemFinder = find.descendant(
          of: reviewItemFinder,
          matching: find.byIcon(Icons.star), // Look for full stars
        );
        // We expect `reviewRating` full stars (e.g., 4 for 4.0)
        expect(starsInReviewItemFinder, findsNWidgets(reviewRating.floor()), reason: "Should find ${reviewRating.floor()} full stars in the submitted review.");
        
        // If rating has a .5 part, check for star_half
        if (reviewRating - reviewRating.floor() >= 0.5) {
            final halfStarInReviewItemFinder = find.descendant(
              of: reviewItemFinder,
              matching: find.byIcon(Icons.star_half),
            );
            expect(halfStarInReviewItemFinder, findsOneWidget, reason: "Should find one half star if rating is X.5.");
        }


      } else if (await tester.widget<dynamic>(loginToReviewMessageFinder, skipOffstage: false).then((_) => true).catchError((_) => false)) {
        // --- User is NOT logged in: "Login required" message is shown ---
        print("INFO: 'Você precisa estar logado para avaliar.' message found. Test verifies this state.");
        expect(loginToReviewMessageFinder, findsOneWidget);
      } else {
        // Neither input field nor login message was found. This is an unexpected state.
        fail('Expected to find either the review input field or the "login required" message, but found neither.');
      }
    });
  });
}
