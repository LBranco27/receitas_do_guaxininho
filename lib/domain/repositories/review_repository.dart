// lib/domain/repositories/review_repository.dart

import '../entities/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviews({
    required int recipeId, // Changed from String to int
    int page = 0,
    int limit = 10,
  });

  Future<Review> addReview({
    required int recipeId, // Changed from String to int
    required String userId,
    required int rating,
    String? text,
  });

  // Optional: Update Review
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    String? text,
  });

  // Optional: Delete Review
  Future<void> deleteReview({required String reviewId});

  // Optional: Get average rating for a recipe
  Future<double?> getAverageRating({required int recipeId}); // Changed from String to int
}
