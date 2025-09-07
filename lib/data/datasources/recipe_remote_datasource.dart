import 'package:flutter/foundation.dart'; // Import for debugPrint
// import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/recipe.dart';
import '../db/app_database.dart';
import '../../domain/entities/recipe.dart';

class RecipeRemoteDataSource {
  //Future<Database> get _db async => AppDatabase().database;
  final _supabaseClient = Supabase.instance.client;


  Future<List<Recipe>> getAll({String? search, String? category}) async {
    try {
      var query = _supabaseClient
          .from('recipes')
          .select();

      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('name', '%${search.trim().toLowerCase()}%');
      }

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (kDebugMode) {
        print(
            '[RecipeRemoteDataSource.getAll] Fetching from Supabase table "recipes" with filters: search="$search", category="$category"');
      }

      final response = await query.order('id', ascending: false);

       if (kDebugMode) {
        print('[RecipeRemoteDataSource.getAll] Received ${response
            .length} items from Supabase.');
      }

      final List<Recipe> recipes = response.map((item) {
        try {
          final recipe = Recipe.fromMap(item);
          if (kDebugMode) {
            print('[RecipeRemoteDataSource.getAll] Parsed Recipe: ${recipe
                .name}');
          }
          return recipe;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print(
                '[RecipeRemoteDataSource.getAll Error] Failed to parse recipe from Supabase data: $item');
            print('[RecipeRemoteDataSource.getAll Error Details] $e');
            print('[RecipeRemoteDataSource.getAll StackTrace] $stackTrace');
          }
          return Recipe(
            id: (item)['id'] as int? ?? 0,
            name: 'Error: Could Not Load',
            description: 'Failed to parse recipe from server.',
            ingredients: {},
            steps: [],
            category: '',
            timeMinutes: 0,
            servings: 0,
          );
        }
      }).toList();

      return recipes;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('[RecipeRemoteDataSource.getAll Supabase Error] $error');
        print(
            '[RecipeRemoteDataSource.getAll Supabase StackTrace] $stackTrace');
      }
      // Re-throw the error to be handled by the repository or UI layer
      // You might want to wrap it in a custom exception type
      throw Exception('Failed to fetch recipes from Supabase: $error');
    }
  }

  Future<List> getFromCategory(String category) async {
    try {
      final response = await _supabaseClient.from('recipes')
          .select()
          .eq('category', category);
      return response.map((data) => Recipe.fromMap(data)).toList();
    } catch (e) {
      print('Erro ao buscar receitas por categoria: $e');
      throw Exception('Falha ao buscar receitas por categoria');
    }
  }

  Future<Recipe?> getById(int id) async {
    try {
      final response = await _supabaseClient
          .from('recipes')
          .select()
          .eq("id", id)
          .single();
      return Recipe.fromMap(response);
    } catch (e) {
      if (kDebugMode) {
        print(
            '[RecipeRemoteDataSource.getRecipeById Error] Failed to parse recipe with id $id: $e');
      }
      return null;
    }
  }

  Future<int?> create(Recipe recipe) async {
    try {
      final dataToInsert = recipe.toMap()
        ..remove('id')..remove("isFavorite");

      final response = await _supabaseClient
          .from('recipes')
          .insert(dataToInsert)
          .select()
          .single();
      return Recipe
          .fromMap(response)
          .id;
    } catch (e) {
      print('Erro ao criar receita: $e');
      throw Exception('Falha ao criar receita');
    }
  }

  Future<Recipe> update(Recipe recipe) async {
    try {
      final response = await _supabaseClient
          .from('recipes')
          .update(recipe.toMap()
          ..remove('id'))..remove("isFavorite")
          .eq('id', recipe.id as Object)
          .select()
          .single();
      return Recipe.fromMap(response);
    } catch (e) {
      print('Erro ao atualizar receita: $e');
      throw Exception('Falha ao atualizar receita');
    }
  }

  Future<void> delete(int id) async {
    try {
      final response = await _supabaseClient
          .from('recipes')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erro ao deletar receita: $e');
      throw Exception('Falha ao deletar receita');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _supabaseClient.from('distinct_categories').select(
          'category');
      if (response.isEmpty) {
        return [];
      }
      return response.map((data) => data['category'] as String).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar categorias: $e');
      }
      throw Exception('Falha ao buscar categorias');
    }
  }

  Future<void> addFavorite(int recipeId) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) throw 'Usuário não autenticado';
    await _supabaseClient.from('user_favorites').insert({
      'user_id': userId,
      'recipe_id': recipeId,
    });
  }

  Future<void> removeFavorite(int recipeId) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) throw 'Usuário não autenticado';
    await _supabaseClient
        .from('user_favorites')
        .delete()
        .match({'user_id': userId, 'recipe_id': recipeId});
  }

  Future<List<Recipe>> getFavoriteRecipes({int page = 0, int limit = 10}) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) throw 'Usuário não autenticado';

    final from = page * limit;
    final to = from + limit - 1;

    final favoriteRelations = await _supabaseClient
        .from('user_favorites')
        .select('recipe_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);

    final recipeIds = favoriteRelations.map((fav) => fav['recipe_id'] as int).toList();
    if (recipeIds.isEmpty) return [];

    final response = await _supabaseClient
        .from('recipes')
        .select()
        .inFilter('id', recipeIds);

    final recipes = response.map<Recipe>((data) => Recipe.fromMap(data)).toList();

    return recipes.map((r) => r.copyWith(isFavorite: true)).toList();
  }

}