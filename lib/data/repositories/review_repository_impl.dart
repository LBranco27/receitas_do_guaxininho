// lib/data/repositories/review_repository_impl.dart

import 'package:flutter/foundation.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource _remoteDataSource;

  ReviewRepositoryImpl({required ReviewRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Review>> getReviews({
    required int recipeId,
    int page = 0,
    int limit = 10,
  }) async {
    if (kDebugMode) {
      print(
          '[ReviewRepositoryImpl.getReviews] Passing to remoteDataSource for recipeId: $recipeId');
    }
    try {
      return await _remoteDataSource.getReviews(
          recipeId: recipeId, page: page, limit: limit);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
            '[ReviewRepositoryImpl.getReviews Error] Exception from remoteDataSource: $e');
        print(
            '[ReviewRepositoryImpl.getReviews StackTrace] $stackTrace');
      }
      throw Exception('Failed to get reviews from repository: $e');
    }
  }

  @override
  Future<Review> addReview({
    required int recipeId,
    required String userId,
    required int rating,
    String? text,
  }) async {
    if (kDebugMode) {
      print(
          '[ReviewRepositoryImpl.addReview] Passing to remoteDataSource for recipeId: $recipeId');
    }
    try {
      return await _remoteDataSource.addReview(
        recipeId: recipeId,
        userId: userId,
        rating: rating,
        text: text,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
            '[ReviewRepositoryImpl.addReview Error] Exception from remoteDataSource: $e');
        print(
            '[ReviewRepositoryImpl.addReview StackTrace] $stackTrace');
      }
      throw "Failed to add review through repository: $e"; // Re-throw original exception to preserve specific error messages (e.g., already reviewed)
    }
  }

  @override
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    String? text,
  }) async {
     if (kDebugMode) {
      print(
          '[ReviewRepositoryImpl.updateReview] Passing to remoteDataSource for reviewId: $reviewId');
    }
    try {
      return await _remoteDataSource.updateReview(
        reviewId: reviewId,
        rating: rating,
        text: text,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
            '[ReviewRepositoryImpl.updateReview Error] Exception from remoteDataSource: $e');
        print(
            '[ReviewRepositoryImpl.updateReview StackTrace] $stackTrace');
      }
      throw Exception('Failed to update review through repository: $e');
    }
  }

  @override
  Future<void> deleteReview({required String reviewId}) async {
    if (kDebugMode) {
      print(
          '[ReviewRepositoryImpl.deleteReview] Passing to remoteDataSource for reviewId: $reviewId');
    }
    try {
      await _remoteDataSource.deleteReview(reviewId: reviewId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
            '[ReviewRepositoryImpl.deleteReview Error] Exception from remoteDataSource: $e');
        print(
            '[ReviewRepositoryImpl.deleteReview StackTrace] $stackTrace');
      }
      throw Exception('Failed to delete review through repository: $e');
    }
  }

  @override
  Future<double?> getAverageRating({required int recipeId}) async {
     if (kDebugMode) {
      print(
          '[ReviewRepositoryImpl.getAverageRating] Passing to remoteDataSource for recipeId: $recipeId');
    }
    try {
      return await _remoteDataSource.getAverageRating(recipeId: recipeId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
            '[ReviewRepositoryImpl.getAverageRating Error] Exception from remoteDataSource: $e');
        print(
            '[ReviewRepositoryImpl.getAverageRating StackTrace] $stackTrace');
      }
      // Depending on desired behavior, could rethrow or return null/default
      return null;
    }
  }
}
