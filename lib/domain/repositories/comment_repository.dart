import '../entities/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getComments({
    required String recipeId,
    int page = 0,
    int limit = 20,
  });

  /// Adds a new comment to a recipe.
  ///
  /// Takes [recipeId], the [userId] of the commenter, and the [text] of the comment.
  /// Returns the newly created [Comment] object.
  Future<Comment> addComment({
    required String recipeId,
    required String userId,
    required String text,
  });

  /// Deletes a comment by its [commentId].
  ///
  /// Typically, you'd also check if the user requesting deletion is the author
  /// or has moderation privileges. This logic might reside in the ViewModel or
  /// be enforced by database policies.
  Future<void> deleteComment({
    required String commentId,
  });

  Future<Comment> updateComment({
    required String commentId,
    required String newText,
  });
}
