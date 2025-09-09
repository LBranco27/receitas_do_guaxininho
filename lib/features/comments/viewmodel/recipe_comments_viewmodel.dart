// lib/features/comments/viewmodel/recipe_comments_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/repositories/comment_repository.dart';
import '../../../data/repositories/comment_repository_impl.dart';
import '../../../data/datasources/comment_remote_datasource.dart'; // Needed for CommentRepositoryImpl dependency

// --- Comment Repository Provider ---
// This provides an instance of CommentRepository.
// You might already have a central place for such providers. If so, you can use that.
// For now, it's placed here for convenience.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  // CommentRepositoryImpl requires CommentRemoteDataSource
  // CommentRemoteDataSource doesn't require constructor params in its current form
  return CommentRepositoryImpl(CommentRemoteDataSource());
});

// --- Recipe Comments ViewModel ---
// Uses AsyncNotifierProviderFamily to take recipeId as a parameter.
// The state of this notifier will be AsyncValue<List<Comment>>.

final recipeCommentsProvider = AutoDisposeAsyncNotifierProviderFamily<
    RecipeCommentsViewModel, List<Comment>, String>(() {
  return RecipeCommentsViewModel();
});

class RecipeCommentsViewModel
    extends AutoDisposeFamilyAsyncNotifier<List<Comment>, String> {
  // The build method is called when the provider is first read.
  // It should return the initial state, typically by fetching data.
  // 'arg' here is the recipeId passed to the family provider.
  @override
  Future<List<Comment>> build(String recipeId) async {
    // Access the CommentRepository
    final commentRepository = ref.watch(commentRepositoryProvider);
    // Fetch initial comments
    return commentRepository.getComments(recipeId: recipeId);
  }

  // Method to add a new comment
  Future<void> addComment({
    required String recipeId, // recipeId is also available via `arg`
    required String userId,
    required String text,
  }) async {
    // Access the CommentRepository
    final commentRepository = ref.read(commentRepositoryProvider);

    // Set state to loading optimistically or handle as needed
    // For AsyncNotifier, performing an async operation and then re-fetching
    // or updating the state will automatically manage loading/error states.

    try {
      await commentRepository.addComment(
        recipeId: recipeId, // or use `arg`
        userId: userId,
        text: text,
      );
      // After adding, refresh the list of comments
      // This will re-run the `build` method if using ref.invalidateSelf()
      // or by directly updating the state if we manage it manually.
      // For simplicity with AsyncNotifier, re-fetching is straightforward:
      ref.invalidateSelf(); // This will trigger 'build' again.
      // Wait for the state to be updated
      await future; // 'future' is the Future from the last 'build' call
    } catch (e) {
      // The error will be reflected in the provider's state by AsyncNotifier
      // if not caught and rethrown manually.
      // For more specific error handling in UI, you might update state with error.
      // For now, relying on AsyncNotifier's error handling.
      print('Error adding comment in ViewModel: $e');
      // Re-throw if you want the provider to be in an error state based on this.
      // If `build` is re-run (e.g. via invalidateSelf), an error there
      // would also put the provider in an error state.
      throw "Error adding comment";
    }
  }

  // Optional: Method to delete a comment
  Future<void> deleteComment({required String commentId}) async {
    final commentRepository = ref.read(commentRepositoryProvider);
    try {
      await commentRepository.deleteComment(commentId: commentId);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      print('Error deleting comment in ViewModel: $e');
      throw "Error deleting comment";
    }
  }
}
