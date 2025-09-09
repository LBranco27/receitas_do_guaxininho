import 'package:receitas_do_guaxininho/features/recipes/view/recipe_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20.0,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData iconData;
        if (index < rating.floor()) {
          iconData = Icons.star;
        } else if (index < rating && (rating - index) >= 0.5) {
          iconData = Icons.star_half;
        } else {
          iconData = Icons.star_border;
        }
        return Icon(iconData, size: size, color: color);
      }),
    );
  }
}


void main() {
  group('RatingStars Widget', () {
    testWidgets('displays correct stars for a whole number rating', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp( // MaterialApp is needed for Directionality, themes, etc.
          home: Scaffold(
            body: RatingStars(rating: 3.0),
          ),
        ),
      );

      // Act & Assert
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_half), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('displays correct stars for a half rating (e.g., 3.5)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStars(rating: 3.5),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_half), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNWidgets(1));
    });

    testWidgets('displays correct stars for a rating like 3.2 (rounds down for half star)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStars(rating: 3.2),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_half), findsNothing); // 3.2 means no half star shown
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('displays correct stars for a rating like 3.7 (rounds up for half star)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStars(rating: 3.7),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.star), findsNWidgets(3)); // 3 full stars
      expect(find.byIcon(Icons.star_half), findsOneWidget); // 1 half star for .7
      expect(find.byIcon(Icons.star_border), findsNWidgets(1)); // 1 empty star
    });


    testWidgets('displays all borders for 0 rating', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStars(rating: 0.0),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_half), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    });

    testWidgets('displays all full stars for 5 rating', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStars(rating: 5.0),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.byIcon(Icons.star_half), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('applies custom size and color', (WidgetTester tester) async {
      // Arrange
      const testSize = 30.0;
      const testColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStars(rating: 2.5, size: testSize, color: testColor),
          ),
        ),
      );

      // Act: Find all Icon widgets within RatingStars
      // We expect 2 full stars, 1 half star, 2 border stars.
      // Total 5 icons.
      final iconWidgets = tester.widgetList<Icon>(find.byType(Icon));

      // Assert
      expect(iconWidgets.length, 5); // Ensure all 5 icons are found

      for (var iconWidget in iconWidgets) {
        expect(iconWidget.size, testSize);
        expect(iconWidget.color, testColor);
      }
      // More specific check for the icons themselves
      expect(find.byIcon(Icons.star), findsNWidgets(2));
      expect(find.byIcon(Icons.star_half), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });
  });
}