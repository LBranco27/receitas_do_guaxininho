import '../entities/recipe.dart';

abstract class RecipeRepository {
  Future<List<Recipe>> getAll({String? search, String? category});
  Future<List> getFromCategory(String category);
  Future<Recipe?> getById(int id);
  Future<int?> create(Recipe recipe);
  Future<Recipe> update(Recipe recipe);
  Future<void> delete(int id);
  Future<void> toggleFavorite(int id, bool value);
  Future<List<String>> getCategories();

  // (opcional para V2)
}
