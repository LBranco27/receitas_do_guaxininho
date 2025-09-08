import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/recipe.dart';
import '../db/app_database.dart';

class RecipeLocalDataSource {
  Future<Database> get _db async => AppDatabase().database;

  Future<List<Recipe>> getAll({String? search, String? category}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (search != null && search.trim().isNotEmpty) {
      where.add('LOWER(name) LIKE ?');
      args.add('%${search.toLowerCase()}%');
    }
    if (category != null && category.isNotEmpty) {
      where.add('category = ?');
      args.add(category);
    }

    final maps = await db.query(
      'recipes',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'id DESC',
    );
    
    return maps.map((e) {
      if (kDebugMode) {
        print('[RAW MAP] id: ${e['id']}, name: ${e['name']}, ingredients: ${e['ingredients']}');
      }
      try {
        final recipe = Recipe.fromMap(e);
        if (kDebugMode) {
          print('[PARSED RECIPE] $recipe');
        }
        return recipe;
      } catch (ex, stackTrace) {
        if (kDebugMode) {
          print('[RecipeLocalDataSource.getAll Error] Failed to parse recipe with id ${e['id']}: $ex');
          print('[RecipeLocalDataSource.getAll StackTrace] $stackTrace');
        }
        return Recipe(name: 'Error Recipe', description: '', owner: '', ingredients: {"Erro":["Falha ao carregar receita com ID ${e['id']}"]}, steps: [], category: '', timeMinutes: 0, servings: 0, id: (e['id'] as int?) ?? 0);
      }
    }).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT DISTINCT category FROM recipes');
    return rows.map((e) => e['category'] as String).toList();
  }

  Future<Recipe?> getById(int id) async {
    final db = await _db;
    final maps = await db.query('recipes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    try {
      return Recipe.fromMap(maps.first);
    } catch (e) {
       if (kDebugMode) {
        print('[RecipeLocalDataSource.getById Error] Failed to parse recipe with id $id: $e');
      }
      return null;
    }
  }

  Future<int> insert(Recipe recipe) async {
    final db = await _db;
    return db.insert('recipes', recipe.toMap());
  }

  Future<void> toggleFavorite(int id, bool value) async {
    final db = await _db;
    await db.update('recipes', {'is_favorite': value ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> update(Recipe r) async {
    final db = await _db;
    await db.update('recipes', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM recipes'),
    )!;
    if (count > 0) return;

    final demo1 = Recipe(
      name: 'Salada azul com frango',
      description: 'Refrescante e rápida para o dia a dia.',
      owner: '',
      ingredients: {
        "Proteína": ["250 g de peito de frango"],
        "Salada Base": ["1 alface romana", "Croutons a gosto"],
        "Tempero": ["Sal a gosto", "Pimenta a gosto", "Azeite a gosto", "Parmesão a gosto"]
      },
      steps: [
        'Grelhe o frango e fatie.',
        'Lave e quebre a alface.',
        'Misture tudo com azeite, sal e pimenta.',
        'Finalize com croutons e parmesão.',
      ],
      category: 'Saladas',
      timeMinutes: 10,
      servings: 3,
      imagePath: null,
    );
    final demo2 = Recipe(
      name: 'Martini de Morango',
      description: 'Refrescante e rápida para o dia a dia.',
      owner: '',
      ingredients: {
        "Bebida": ["200ml de martini de preferência"],
        "Fruta": ["100g de morangos selecionados à mão por himalios"]
      },
      steps: [
        "Esmague os morangos com suas mãos.",
        "Coloque os morangos totalmente esmagados em um recipiente (podendo ser uma taça).",
        "Adicione o martini e misture a bebida com sua mão (esmague pedaços grandes de morango se precisar).",
      ],
      category: 'Saladas', // Originalmente estava Saladas, mantendo consistência.
      timeMinutes: 5,
      servings: 1,
      imagePath: "assets/images/martini_de_morango.png",
    );

    await insert(demo2);
    await insert(demo1);
  }
}