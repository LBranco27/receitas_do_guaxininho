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
    return maps.map((e) => Recipe.fromMap(e)).toList();
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
    return Recipe.fromMap(maps.first);
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

  // (opcional V2)
  Future<void> update(Recipe r) async {
    final db = await _db;
    await db.update('recipes', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // seed inicial para brincar
  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM recipes'),
    )!;
    if (count > 0) return;

    final demo = Recipe(
      name: 'Salada verde com frango',
      description: 'Refrescante e rápida para o dia a dia.',
      ingredients: [
        '1 alface romana',
        '250 g de peito de frango',
        'Croutons',
        'Parmesão a gosto',
        'Sal, pimenta e azeite',
      ],
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

    await insert(demo);
  }
}
