import 'package:flutter/foundation.dart'; // Import for debugPrint
// import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/recipe.dart';
import '../db/app_database.dart';
import '../../domain/entities/recipe.dart';

class RecipeRemoteDataSource {
  //Future<Database> get _db async => AppDatabase().database;
  final _supabaseClient = Supabase.instance.client;


  Future<List> getAll() async {
    try {
      final response = await _supabaseClient.from('recipes').select();
      return response.map((data) => Recipe.fromMap(data)).toList();
    } catch (e) {
      print('Erro ao buscar receitas: $e');
      throw Exception('Falha ao buscar receitas');
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
        print('[RecipeRemoteDataSource.getRecipeById Error] Failed to parse recipe with id $id: $e');
      }
      return null;
    }
  }

  Future<int?> create(Recipe recipe) async {
    try {
      final Map<String, dynamic> recipeData = recipe.toMap();

      final dataToInsert = recipe.toMap()
        ..remove('id');

      final response = await _supabaseClient
        .from('recipes')
        .insert(dataToInsert)
        .select()
        .single();
      return Recipe.fromMap(response).id;
    } catch (e) {
      print('Erro ao criar receita: $e');
      throw Exception('Falha ao criar receita');
    }
  }

  Future<Recipe> update(Recipe recipe) async {
    try {
      final response = await _supabaseClient
          .from('recipes')
          .update(recipe.toMap()..remove('id'))
          .eq('id', recipe.id)
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
      final response = await _supabaseClient.from('distinct_categories').select('category');
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

  Future<void> toggleFavorite(int id, bool value) async {
    try {
      final response = await _supabaseClient
          .from('recipes')
          .update({'is_favorite': !value})
          .eq('id', id)
          .select('id');
      if (response.isEmpty) {
        if (kDebugMode) {
          print('Nenhuma receita encontrada com o id $id para alternar favorito.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao alternar favorito para receita $id: $e');
      }
      throw Exception('Falha ao alternar estado de favorito');
    }
  }