import '../entities/recipe.dart';

abstract class RecipeRepository {
  Future<List<Recipe>> getAll({String? search, String? category});
  Future<List<String>> getCategories();
  Future<Recipe?> getById(int id);
  Future<int> create(Recipe recipe);
  Future<void> toggleFavorite(int id, bool value);

  // (opcional para V2)
  Future<void> update(Recipe recipe) async {}
  Future<void> delete(int id) async {}
}
