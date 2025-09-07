import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/recipe_remote_datasource.dart';
import '../../../data/repositories/recipe_repository_impl.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/repositories/recipe_repository.dart';
import '../../profile/viewmodel/favorite_recipes_viewmodel.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl(RecipeRemoteDataSource());
});

final favoriteRecipeIdsProvider = FutureProvider<Set<int>>((ref) async {
  final repo = ref.watch(recipeRepositoryProvider);
  final favoriteRecipes = await repo.getFavoriteRecipes(limit: 9999);
  return favoriteRecipes.map((r) => r.id!).toSet();
});

// -------------------- STATE --------------------
class HomeState {
  final bool loading;
  final String? error;
  final String search;
  final String? category;
  final List<Recipe> recipes;

  const HomeState({
    this.loading = false,
    this.error,
    this.search = '',
    this.category,
    this.recipes = const [],
  });

  HomeState copyWith({
    bool? loading,
    String? error,
    String? search,
    String? category,
    List<Recipe>? recipes,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      error: error == '' ? null : (error ?? this.error),
      search: search ?? this.search,
      category: category ?? this.category,
      recipes: recipes ?? this.recipes,
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
      final recipes = await repo.getAll(
        search: state.search.isEmpty ? null : state.search,
        category: state.category,
      );
      final favoriteIds = await ref.read(favoriteRecipeIdsProvider.future);

      final updatedRecipes = recipes.map((recipe) {
        return recipe.copyWith(isFavorite: favoriteIds.contains(recipe.id));
      }).toList();

      state = state.copyWith(loading: false, recipes: updatedRecipes);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void updateFavoritesState(Set<int> favoriteIds) {
    final updatedRecipes = state.recipes.map((recipe) {
      return recipe.copyWith(isFavorite: favoriteIds.contains(recipe.id));
    }).toList();
    state = state.copyWith(recipes: updatedRecipes);
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

  void setSearch(String value) {
    state = state.copyWith(search: value);
    load();
  }

  void setCategory(String? value) {
    state = state.copyWith(category: value);
    load();
  }

  Future<void> refresh() => load();
}

// -------------------- PROVIDER --------------------
final homeVmProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  final vm = HomeViewModel(repo, ref);
  vm.load();

  ref.listen(favoriteRecipeIdsProvider, (previous, next) {
    if (next.hasValue) {
      vm.updateFavoritesState(next.value!);
    }
  });

  return vm;
});

