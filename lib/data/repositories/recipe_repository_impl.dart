import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_local_datasource.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeLocalDataSource ds;
  RecipeRepositoryImpl(this.ds);

  @override
  Future<int> create(Recipe recipe) => ds.insert(recipe);

  @override
  Future<List<Recipe>> getAll({String? search, String? category}) =>
      ds.getAll(search: search, category: category);

  @override
  Future<Recipe?> getById(int id) => ds.getById(id);

  @override
  Future<void> toggleFavorite(int id, bool value) =>
      ds.toggleFavorite(id, value);

  @override
  Future<List<String>> getCategories() => ds.getCategories();

  @override
  Future<void> update(Recipe recipe) => ds.update(recipe);

  @override
  Future<void> delete(int id) => ds.delete(id);
}
