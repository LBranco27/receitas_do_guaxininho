import '../entities/recipe.dart';

abstract class RecipeRepository {

  Future<List<Recipe>> getAll({String? search, String? category});
  Future<List> getFromCategory(String category);
  Future<Recipe?> getById(int id);
  Future<int?> create(Recipe recipe);
  Future<Recipe> update(Recipe recipe);
  Future<void> delete(int id);
  Future<List<String>> getCategories();
  Future<void> addFavorite(int recipeId);
  Future<void> removeFavorite(int recipeId);
  Future<List<Recipe>> getFavoriteRecipes();
  Future<List<Recipe>> getMyRecipes({int page = 0, int limit = 10});
  Future<List<Recipe>> getUserRecipes({required String userId, required int page, required int limit});
  Future<List<Recipe>> getPopularRecipes({int limit = 10});

}
