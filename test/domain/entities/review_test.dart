import 'package:flutter_test/flutter_test.dart';
import 'package:receitas_do_guaxininho/domain/entities/review.dart';

void main() {
  group('Review Entity', () {
    late Review initialReview;

    setUp(() {
      initialReview = Review(
        id: 'HAHAHA',
        recipeId: 1,
        userId: 'IMHEREYOULEAVE',
        rating: 4,
        text: 'O medo abundante de todas as verdades!',
        createdAt: DateTime(2027, 27, 27, 27, 27, 27),
        userName: 'Irineu',
        userAvatarUrl: 'http://example.com/avatar.png',
      );
    });

    test('copyWith should update specified fields and keep others', () {
      const newRating = 5;
      const newText = 'Esse é o que nós separa da verdadeira alma alocada nas profundezas. uau uwu!';

      final updatedReview = initialReview.copyWith(
        rating: newRating,
        text: newText,
      );

      expect(updatedReview.id, initialReview.id); // Should remain the same
      expect(updatedReview.recipeId, initialReview.recipeId); // Should remain the same
      expect(updatedReview.userId, initialReview.userId); // Should remain the same
      expect(updatedReview.rating, newRating); // Should be updated
      expect(updatedReview.text, newText); // Should be updated
      expect(updatedReview.createdAt, initialReview.createdAt); // Should remain the same
      expect(updatedReview.userName, initialReview.userName); // Should remain the same
      expect(updatedReview.userAvatarUrl, initialReview.userAvatarUrl); // Should remain the same
    });

    test('copyWith should allow setting text to null explicitly', () {
      final reviewWithNullText = initialReview.copyWith(
        text: null,
        allowNullText: true,
      );

      expect(reviewWithNullText.text, isNull);
      expect(reviewWithNullText.rating, initialReview.rating);
    });

    test('copyWith should keep original text if new text is null and allowNullText is false (or default)', () {
      final reviewWithSameText = initialReview.copyWith(
        text: null,
      );

      // Assert
      expect(reviewWithSameText.text, initialReview.text);
      expect(reviewWithSameText.rating, initialReview.rating);
    });

    test('copyWith with no arguments should return an identical object', () {
      final copiedReview = initialReview.copyWith();

      expect(copiedReview.id, initialReview.id);
      expect(copiedReview.recipeId, initialReview.recipeId);
      expect(copiedReview.userId, initialReview.userId);
      expect(copiedReview.rating, initialReview.rating);
      expect(copiedReview.text, initialReview.text);
      expect(copiedReview.createdAt, initialReview.createdAt);
      expect(copiedReview.userName, initialReview.userName);
      expect(copiedReview.userAvatarUrl, initialReview.userAvatarUrl);
    });
  });
}
