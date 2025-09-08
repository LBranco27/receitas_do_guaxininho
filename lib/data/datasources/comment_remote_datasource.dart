// lib/data/datasources/comment_remote_datasource.dart

import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/comment.dart';
// Removed redundant import: import 'comment_remote_datasource.dart';

class CommentRemoteDataSource {
  final _supabaseClient = Supabase.instance.client; // Made private

  Future<List<Comment>> getComments({
    required String recipeId,
    int page = 0,
    int limit = 20,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    if (kDebugMode) {
      print(
          '[CommentRemoteDataSource.getComments] Fetching for recipeId: $recipeId, page: $page, limit: $limit');
    }

    try {
      final response = await _supabaseClient
          .from('comments')
          .select('*, profiles(name, avatar_url)')
          .eq('recipe_id', recipeId)
          .order('created_at', ascending: false)
          .range(from, to);

      if (kDebugMode) {
        print(
            '[CommentRemoteDataSource.getComments] Received ${response.length} comments from Supabase.');
      }

      final comments = response.map((data) {
        try {
          final profileData = data['profiles'] as Map<String, dynamic>?;
          final comment = Comment(
            id: data['id'] as String,
            recipeId: data['recipe_id'] as int,
            userId: data['user_id'] as String,
            text: data['text'] as String,
            createdAt: DateTime.parse(data['created_at'] as String),
            userName: profileData?['name'] as String?,
            userAvatarUrl: profileData?['avatar_url'] as String?,
          );
          if (kDebugMode) {
            // Potentially log each parsed comment if needed, but can be verbose
            // print('[CommentRemoteDataSource.getComments] Parsed Comment ID: ${comment.id}');
          }
          return comment;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print(
                '[CommentRemoteDataSource.getComments Error] Failed to parse comment from Supabase data: $data');
            print('[CommentRemoteDataSource.getComments Error Details] $e');
            print(
                '[CommentRemoteDataSource.getComments StackTrace] $stackTrace');
          }
          // Fallback or rethrow a more specific parsing error
          rethrow; // Or return a placeholder Comment if that's the desired pattern
        }
      }).toList();

      return comments;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[CommentRemoteDataSource.getComments Supabase Error] $e');
        print(
            '[CommentRemoteDataSource.getComments Supabase StackTrace] $stackTrace');
      }
      throw Exception('Failed to fetch comments: $e');
    }
  }

  Future<Comment> addComment({
    required String recipeId,
    required String userId,
    required String text,
  }) async {
    if (kDebugMode) {
      print(
          '[CommentRemoteDataSource.addComment] Adding comment for recipeId: $recipeId, userId: $userId');
    }
    try {
      final response = await _supabaseClient
          .from('comments')
          .insert({
            'recipe_id': recipeId,
            'user_id': userId,
            'text': text,
          })
          .select('*, profiles(name, avatar_url)')
          .single();

      if (kDebugMode) {
        print(
            '[CommentRemoteDataSource.addComment] Successfully added comment, ID: ${response['id']}');
      }
      
      final profileData = response['profiles'] as Map<String, dynamic>?;
      return Comment(
        id: response['id'] as String,
        recipeId: response['recipe_id'] as int,
        userId: response['user_id'] as String,
        text: response['text'] as String,
        createdAt: DateTime.parse(response['created_at'] as String),
        userName: profileData?['name'] as String?,
        userAvatarUrl: profileData?['avatar_url'] as String?,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[CommentRemoteDataSource.addComment Supabase Error] $e');
        print(
            '[CommentRemoteDataSource.addComment Supabase StackTrace] $stackTrace');
      }
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> deleteComment({required String commentId}) async {
    if (kDebugMode) {
      print(
          '[CommentRemoteDataSource.deleteComment] Deleting commentId: $commentId');
    }
    try {
      await _supabaseClient
          .from('comments')
          .delete()
          .eq('id', commentId);
      if (kDebugMode) {
        print(
            '[CommentRemoteDataSource.deleteComment] Successfully deleted commentId: $commentId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[CommentRemoteDataSource.deleteComment Supabase Error] $e');
        print(
            '[CommentRemoteDataSource.deleteComment Supabase StackTrace] $stackTrace');
      }
      throw Exception('Failed to delete comment: $e');
    }
  }

  // updateComment remains a stub, similar to how RecipeRemoteDataSource might have started
  // before all methods were fully implemented.
  Future<Comment> updateComment({required String commentId, required String newText}) async {
    if (kDebugMode) {
      print(
          '[CommentRemoteDataSource.updateComment] Attempting to update commentId: $commentId');
    }
    // TODO: Implement update logic similar to RecipeRemoteDataSource.update if needed
    try {
      final response = await _supabaseClient
          .from('comments')
          .update({'text': newText})
          .eq('id', commentId)
          .select('*, profiles(name, avatar_url)')
          .single();
      if (kDebugMode) {
        print('[CommentRemoteDataSource.updateComment] Successfully updated commentId: ${response['id']}');
      }
      final profileData = response['profiles'] as Map<String, dynamic>?;
      return Comment(
        id: response['id'] as String,
        recipeId: response['recipe_id'] as int,
        userId: response['user_id'] as String,
        text: response['text'] as String,
        createdAt: DateTime.parse(response['created_at'] as String),
        userName: profileData?['name'] as String?,
        userAvatarUrl: profileData?['avatar_url'] as String?,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[CommentRemoteDataSource.updateComment Supabase Error] $e');
        print('[CommentRemoteDataSource.updateComment Supabase StackTrace] $stackTrace');
      }
      throw Exception('Failed to update comment: $e');
    }
  }
}
