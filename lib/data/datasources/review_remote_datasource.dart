// lib/data/datasources/review_remote_datasource.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/review.dart';

class ReviewRemoteDataSource {
  final _supabaseClient = Supabase.instance.client;
  static const String _reviewsTable = 'reviews';
  static const String _profilesJoin = 'profiles(name, avatar_url)'; // Corrected to 'name' as per your schema

  Future<List<Review>> getReviews({
    required int recipeId,
    int page = 0,
    int limit = 10,
  }) async {
    final from = page * limit;
    final to = from + limit -1;

    if (kDebugMode) {
      print(
          '[ReviewRemoteDataSource.getReviews] Fetching for recipeId: $recipeId, page: $page, limit: $limit');
    }
    try {
      final response = await _supabaseClient
          .from(_reviewsTable)
          .select('*, $_profilesJoin')
          .eq('recipe_id', recipeId)
          .order('created_at', ascending: false)
          .range(from, to);

      if (kDebugMode) {
        print(
            '[ReviewRemoteDataSource.getReviews] Received ${response.length} reviews from Supabase.');
      }

      final reviews = response.map((data) {
        final profileData = data['profiles'] as Map<String, dynamic>?;
        return Review(
          id: data['id'] as String,
          recipeId: data['recipe_id'] as int,
          userId: data['user_id'] as String,
          rating: data['rating'] as int,
          text: data['review_text'] as String?, // MODIFIED HERE
          createdAt: DateTime.parse(data['created_at'] as String),
          userName: profileData?['name'] as String?,
          userAvatarUrl: profileData?['avatar_url'] as String?,
        );
      }).toList();
      return reviews;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ReviewRemoteDataSource.getReviews Supabase Error] $e');
        print(
            '[ReviewRemoteDataSource.getReviews Supabase StackTrace] $stackTrace');
      }
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<Review> addReview({
    required int recipeId,
    required String userId,
    required int rating,
    String? text,
  }) async {
    if (kDebugMode) {
      print(
          '[ReviewRemoteDataSource.addReview] Adding review for recipeId: $recipeId, userId: $userId, rating: $rating');
    }
    try {
      final response = await _supabaseClient
          .from(_reviewsTable)
          .insert({
            'recipe_id': recipeId,
            'user_id': userId,
            'rating': rating,
            'review_text': text, // MODIFIED HERE
          })
          .select('*, $_profilesJoin')
          .single();

      if (kDebugMode) {
        print(
            '[ReviewRemoteDataSource.addReview] Successfully added review, ID: ${response['id']}');
      }
      final profileData = response['profiles'] as Map<String, dynamic>?;
      return Review(
        id: response['id'] as String,
        recipeId: response['recipe_id'] as int,
        userId: response['user_id'] as String,
        rating: response['rating'] as int,
        text: response['review_text'] as String?, // MODIFIED HERE
        createdAt: DateTime.parse(response['created_at'] as String),
        userName: profileData?['name'] as String?,
        userAvatarUrl: profileData?['avatar_url'] as String?,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ReviewRemoteDataSource.addReview Supabase Error] $e');
        print(
            '[ReviewRemoteDataSource.addReview Supabase StackTrace] $stackTrace');
      }
      if (e is PostgrestException && e.code == '23505') {
        throw Exception('Você já avaliou esta receita.');
      }
      throw Exception('Failed to add review: $e');
    }
  }

  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    String? text,
  }) async {
     if (kDebugMode) {
      print(
          '[ReviewRemoteDataSource.updateReview] Updating reviewId: $reviewId, rating: $rating');
    }
    try {
      final response = await _supabaseClient
          .from(_reviewsTable)
          .update({
            'rating': rating,
            'review_text': text, // MODIFIED HERE
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .select('*, $_profilesJoin')
          .single();
      
      if (kDebugMode) {
        print(
            '[ReviewRemoteDataSource.updateReview] Successfully updated review, ID: ${response['id']}');
      }
      final profileData = response['profiles'] as Map<String, dynamic>?;
      return Review(
        id: response['id'] as String,
        recipeId: response['recipe_id'] as int,
        userId: response['user_id'] as String,
        rating: response['rating'] as int,
        text: response['review_text'] as String?, // MODIFIED HERE
        createdAt: DateTime.parse(response['created_at'] as String),
        userName: profileData?['name'] as String?,
        userAvatarUrl: profileData?['avatar_url'] as String?,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ReviewRemoteDataSource.updateReview Supabase Error] $e');
        print(
            '[ReviewRemoteDataSource.updateReview Supabase StackTrace] $stackTrace');
      }
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview({required String reviewId}) async {
    if (kDebugMode) {
      print('[ReviewRemoteDataSource.deleteReview] Deleting reviewId: $reviewId');
    }
    try {
      await _supabaseClient
          .from(_reviewsTable)
          .delete()
          .eq('id', reviewId);
      if (kDebugMode) {
        print(
            '[ReviewRemoteDataSource.deleteReview] Successfully deleted reviewId: $reviewId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ReviewRemoteDataSource.deleteReview Supabase Error] $e');
        print(
            '[ReviewRemoteDataSource.deleteReview Supabase StackTrace] $stackTrace');
      }
      throw Exception('Failed to delete review: $e');
    }
  }

  Future<double?> getAverageRating({required int recipeId}) async {
    if (kDebugMode) {
      print('[ReviewRemoteDataSource.getAverageRating] For recipeId: $recipeId');
    }
    try {
      final response = await _supabaseClient
          .from(_reviewsTable)
          .select('rating')
          .eq('recipe_id', recipeId);

      if (response.isEmpty) {
        return null;
      }
      double sum = 0;
      for (var row in response) {
        sum += (row['rating'] as num).toDouble();
      }
      return sum / response.length;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ReviewRemoteDataSource.getAverageRating Supabase Error] $e');
        print(
            '[ReviewRemoteDataSource.getAverageRating Supabase StackTrace] $stackTrace');
      }
      return null;
    }
  }
}
