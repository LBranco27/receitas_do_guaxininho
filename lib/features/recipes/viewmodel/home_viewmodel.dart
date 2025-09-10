import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/main.dart';
import '../../../data/datasources/recipe_remote_datasource.dart';
import '../../../data/repositories/recipe_repository_impl.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/repositories/recipe_repository.dart';
import '../../profile/viewmodel/favorite_recipes_viewmodel.dart';
import 'categories_source.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl(RecipeRemoteDataSource());
});

final favoriteRecipeIdsProvider = FutureProvider<Set<int>>((ref) async {
  final authState = ref.watch(authStateProvider);

  if (authState.valueOrNull == null) {
    return {};
  }

  final repo = ref.watch(recipeRepositoryProvider);
  final favoriteRecipes = await repo.getFavoriteRecipes();
  return favoriteRecipes.map((r) => r.id!).toSet();
});

// -------------------- STATE --------------------
class HomeState {
  final bool loading;
  final String? error;
  final String search;
  final Map<String, List<Recipe>> categorizedRecipes;
  final List<String> categories;
  final List<String> allAvailableCategories;
  final List<Recipe> popularRecipes;

  const HomeState({
    this.loading = false,
    this.error,
    this.search = '',
    this.categorizedRecipes = const {},
    this.categories = const [],
    this.allAvailableCategories = const [],
    this.popularRecipes = const [],
  });

  HomeState copyWith({
    bool? loading,
    String? error,
    String? search,
    Map<String, List<Recipe>>? categorizedRecipes,
    List<String>? categories,
    List<String>? allAvailableCategories,
    List<Recipe>? popularRecipes,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      error: error == '' ? null : (error ?? this.error),
      search: search ?? this.search,
      categorizedRecipes: categorizedRecipes ?? this.categorizedRecipes,
      categories: categories ?? this.categories,
      allAvailableCategories:
      allAvailableCategories ?? this.allAvailableCategories,
      popularRecipes: popularRecipes ?? this.popularRecipes,
    );
  }
}

// -------------------- VIEWMODEL --------------------
class HomeViewModel extends StateNotifier<HomeState> {
  final RecipeRepository repo;
  final Ref ref;

  HomeViewModel(this.repo, this.ref) : super(const HomeState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: '');
    try {
      // Categorias dinâmicas conforme a flag global (all vs official)
      final allCats = await ref.read(categoriesProvider.future);
      state = state.copyWith(allAvailableCategories: allCats);

      final results = await Future.wait([
        repo.getPopularRecipes(),
        repo.getAll(search: state.search.isEmpty ? null : state.search),
        ref.read(favoriteRecipeIdsProvider.future),
      ]);

      final popularRecipesRaw = results[0] as List<Recipe>;
      final recipesRaw = results[1] as List<Recipe>;
      final favoriteIds = results[2] as Set<int>;

      final popularRecipes = popularRecipesRaw
          .map((r) => r.copyWith(isFavorite: favoriteIds.contains(r.id)))
          .toList();

      final recipes = recipesRaw
          .map((r) => r.copyWith(isFavorite: favoriteIds.contains(r.id)))
          .toList();

      final newCategorizedRecipes = <String, List<Recipe>>{};
      for (final recipe in recipes) {
        (newCategorizedRecipes[recipe.category] ??= []).add(recipe);
      }
      final newCategories = newCategorizedRecipes.keys.toList()..sort();

      state = state.copyWith(
        loading: false,
        categorizedRecipes: newCategorizedRecipes,
        categories: newCategories,
        popularRecipes: popularRecipes,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void updateFavoritesState(Set<int> favoriteIds) {
    final updatedCategorizedRecipes = <String, List<Recipe>>{};
    state.categorizedRecipes.forEach((category, recipeList) {
      final updatedList = recipeList.map((recipe) {
        return recipe.copyWith(isFavorite: favoriteIds.contains(recipe.id));
      }).toList();
      updatedCategorizedRecipes[category] = updatedList;
    });
    state = state.copyWith(categorizedRecipes: updatedCategorizedRecipes);
  }

  Future<void> toggleFavorite(int recipeId, bool isCurrentlyFavorite) async {
    try {
      if (isCurrentlyFavorite) {
        await repo.removeFavorite(recipeId);
      } else {
        await repo.addFavorite(recipeId);
      }
      ref.invalidate(favoriteRecipeIdsProvider);
      ref.invalidate(favoriteRecipesViewModelProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      ref.invalidate(favoriteRecipeIdsProvider);
    }
  }

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value);
    await load();
  }

  Future<void> refresh() => load();
}

// -------------------- PROVIDER --------------------
final homeVmProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  // Reage à troca de usuário logado
  ref.watch(authStateProvider);

  final repo = ref.watch(recipeRepositoryProvider);
  final vm = HomeViewModel(repo, ref);
  vm.load();

  // Mantém favoritos sincronizados
  ref.listen(favoriteRecipeIdsProvider, (previous, next) {
    if (next.hasValue) {
      vm.updateFavoritesState(next.value!);
    }
  });

  return vm;
});

/// - Se kCategoriesMode == all: retorna TODAS as categorias encontradas.
/// - Se kCategoriesMode == official: interseção com kOfficialCategories.
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(recipeRepositoryProvider);

  final allRecipes = await repo.getAll();

  final set = <String>{};
  for (final r in allRecipes) {
    var c = r.category.trim();
    if (c.isEmpty) continue;

    if (c.toLowerCase() == 'sobremesa') c = 'Sobremesas';

    set.add(c);
  }

  List<String> result = set.toList();

  if (kCategoriesMode == CategoriesMode.official) {
    result = result.where((c) => kOfficialCategories.contains(c)).toList();
  }

  result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result;
});
