import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_remote_datasource.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource ds;
  CommentRepositoryImpl(this.ds);

  @override
  Future<List<Comment>> getComments({
  required String recipeId,
  int page = 0,
  int limit = 20,
  }) => ds.getComments(recipeId: recipeId);

  @override
  Future<Comment> addComment({
  required String recipeId,
  required String userId,
  required String text,
  }) => ds.addComment(recipeId: recipeId, userId: userId, text: text);

  @override
  Future<void> deleteComment({
  required String commentId,
  }) => ds.deleteComment(commentId: commentId);

  @override
  Future<Comment> updateComment({
  required String commentId,
  required String newText,
  }) => ds.updateComment(commentId: commentId, newText: newText);
}