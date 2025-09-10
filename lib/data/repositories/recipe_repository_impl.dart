import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_local_datasource.dart';
import '../datasources/recipe_remote_datasource.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeRemoteDataSource ds;
  RecipeRepositoryImpl(this.ds);

  @override
  Future<List<Recipe>> getAll({String? search, String? category}) =>
      ds.getAll(search: search, category: category); // <- FIX

  @override
  Future<List> getFromCategory(String category) => ds.getFromCategory(category);

  @override
  Future<Recipe?> getById(int id) => ds.getById(id);

  @override
  Future<int?> create(Recipe recipe) => ds.create(recipe);

  @override
  Future<Recipe> update(Recipe recipe) => ds.update(recipe);

  @override
  Future<void> delete(int id) => ds.delete(id);

  @override
  Future<List<String>> getCategories() => ds.getCategories();

  @override
  Future<void> addFavorite(int recipeId) => ds.addFavorite(recipeId);

  @override
  Future<void> removeFavorite(int recipeId) => ds.removeFavorite(recipeId);

  @override
  Future<List<Recipe>> getFavoriteRecipes({int page = 0, int limit = 10}) =>
      ds.getFavoriteRecipes();

  @override
  Future<List<Recipe>> getMyRecipes({int page = 0, int limit = 10}) =>
      ds.getMyRecipes();

  @override
  Future<List<Recipe>> getUserRecipes({
    required String userId,
    required int page,
    required int limit,
  }) => ds.getUserRecipes(userId: userId, page: page, limit: limit);

  @override
  Future<List<Recipe>> getPopularRecipes({int limit = 10}) => ds.getPopularRecipes(limit: limit);

}