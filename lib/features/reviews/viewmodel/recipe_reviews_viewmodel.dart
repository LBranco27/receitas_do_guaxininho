// lib/features/reviews/viewmodel/recipe_reviews_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../data/repositories/review_repository_impl.dart';
import '../../../data/datasources/review_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added for supabaseClientProvider

// --- Review Repository Provider ---
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(remoteDataSource: ReviewRemoteDataSource());
});

// --- Recipe Reviews ViewModel ---
// Holds the list of reviews and average rating
class RecipeReviewsState {
  final AsyncValue<List<Review>> reviews;
  final AsyncValue<double?> averageRating;
  final Review? currentUserReview; // To check if the current user has already reviewed

  RecipeReviewsState({
    required this.reviews,
    required this.averageRating,
    this.currentUserReview,
  });

  RecipeReviewsState copyWith({
    AsyncValue<List<Review>>? reviews,
    AsyncValue<double?>? averageRating,
    Review? currentUserReview,
    bool allowNullCurrentUserReview = false,
  }) {
    return RecipeReviewsState(
      reviews: reviews ?? this.reviews,
      averageRating: averageRating ?? this.averageRating,
      currentUserReview: allowNullCurrentUserReview ? currentUserReview : (currentUserReview ?? this.currentUserReview),
    );
  }
}

final recipeReviewsProvider = AutoDisposeStateNotifierProviderFamily<
    RecipeReviewsViewModel, RecipeReviewsState, int>((ref, recipeId) { // recipeId is int
  return RecipeReviewsViewModel(ref, recipeId);
});

class RecipeReviewsViewModel extends StateNotifier<RecipeReviewsState> {
  final Ref _ref;
  final int _recipeId; // recipeId is int
  final ReviewRepository _reviewRepository;

  RecipeReviewsViewModel(this._ref, this._recipeId)
      : _reviewRepository = _ref.read(reviewRepositoryProvider),
        super(RecipeReviewsState(
          reviews: const AsyncValue.loading(),
          averageRating: const AsyncValue.loading(),
          currentUserReview: null,
        )) {
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      fetchReviews(),
      fetchAverageRating(),
      // fetchCurrentUserReview(), // Call this after user ID is available or if needed
    ]);
  }
  
  // Method to explicitly fetch current user's review if needed after login
  Future<void> fetchCurrentUserReview(String currentUserId) async {
    if (currentUserId.isEmpty) {
        state = state.copyWith(currentUserReview: null, allowNullCurrentUserReview: true);
        return;
    }
    try {
        // A bit hacky to fetch all reviews just to find one. 
        // Consider adding a dedicated repository/datasource method if performance is an issue.
        final allReviews = await _reviewRepository.getReviews(recipeId: _recipeId, limit: 100); 
        Review? userReview;
        try {
            userReview = allReviews.firstWhere((r) => r.userId == currentUserId);
        } catch (e) {
            userReview = null; // Not found
        }

        if (userReview != null) { 
             state = state.copyWith(currentUserReview: userReview);
        } else {
            state = state.copyWith(currentUserReview: null, allowNullCurrentUserReview: true);
        }

    } catch (e) {
        state = state.copyWith(currentUserReview: null, allowNullCurrentUserReview: true);
         print('Error fetching current user review: $e');
    }
  }


  Future<void> fetchReviews({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(reviews: const AsyncValue.loading());
    }
    try {
      final reviewsData =
          await _reviewRepository.getReviews(recipeId: _recipeId);
      state = state.copyWith(reviews: AsyncValue.data(reviewsData));
      
      final currentUserId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
      if(currentUserId != null && currentUserId.isNotEmpty) {
          Review? userReview;
          try {
            userReview = reviewsData.firstWhere((r) => r.userId == currentUserId);
          } catch (e) {
            userReview = null; // Not found
          }
          if (userReview != null) {
              state = state.copyWith(currentUserReview: userReview);
          } else {
               state = state.copyWith(currentUserReview: null, allowNullCurrentUserReview: true);
          }
      }

    } catch (e, stack) {
      state = state.copyWith(reviews: AsyncValue.error(e, stack));
    }
  }

  Future<void> fetchAverageRating({bool refresh = false}) async {
     if (refresh) {
      state = state.copyWith(averageRating: const AsyncValue.loading());
    }
    try {
      final avgRating =
          await _reviewRepository.getAverageRating(recipeId: _recipeId);
      state = state.copyWith(averageRating: AsyncValue.data(avgRating));
    } catch (e, stack) {
      state = state.copyWith(averageRating: AsyncValue.error(e, stack));
    }
  }

  Future<void> addOrUpdateReview({
    required String userId,
    required int rating,
    String? text,
  }) async {
    try {
      if (state.currentUserReview != null && state.currentUserReview!.id.isNotEmpty) {
        // Update existing review
        await _reviewRepository.updateReview(
          reviewId: state.currentUserReview!.id,
          rating: rating,
          text: text,
        );
      } else {
        // Add new review
        await _reviewRepository.addReview(
          recipeId: _recipeId,
          userId: userId,
          rating: rating,
          text: text,
        );
      }
      // Refresh data
      await _fetchInitialData(); // Re-fetch all, including the updated user review
    } catch (e) {
      print('Error adding/updating review in ViewModel: $e');
      throw "Error adding/updating review in ViewModel"; // Re-throw to be caught by UI
    }
  }

  Future<void> deleteCurrentUserReview() async {
    if (state.currentUserReview == null || state.currentUserReview!.id.isEmpty) return;
    try {
      await _reviewRepository.deleteReview(reviewId: state.currentUserReview!.id);
      state = state.copyWith(currentUserReview: null, allowNullCurrentUserReview: true); // Clear user review
      await _fetchInitialData(); // Refresh list and average
    } catch (e) {
      print('Error deleting review in ViewModel: $e');
      throw "Error deleting review in ViewModel";
    }
  }
}

// Provider for Supabase client, if not already defined elsewhere
final supabaseClientProvider = Provider((ref) => Supabase.instance.client);
