import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_local_datasource.dart';
import '../datasources/recipe_remote_datasource.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  //final RecipeLocalDataSource ds;
  final RecipeRemoteDataSource ds;
  RecipeRepositoryImpl(this.ds);

  @override
  Future<List<Recipe>> getAll({String? search, String? category}) =>
      ds.getAll();

  @override
  Future<List> getFromCategory(String category) =>
      ds.getFromCategory(category);

  @override
  Future<Recipe?> getById(int id) => ds.getById(id);

  @override
  Future<int?> create(Recipe recipe) => ds.create(recipe);

  @override
  Future<Recipe> update(Recipe recipe) => ds.update(recipe);

  @override
  Future<void> delete(int id) => ds.delete(id);

  @override
  Future<void> toggleFavorite(int id, bool value) =>
      ds.toggleFavorite(id, value);

  @override
  Future<List<String>> getCategories() => ds.getCategories();
}
