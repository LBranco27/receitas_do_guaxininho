import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/main.dart';
import '../../../data/datasources/recipe_remote_datasource.dart';
import '../../../data/repositories/recipe_repository_impl.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/repositories/recipe_repository.dart';
import '../../profile/viewmodel/favorite_recipes_viewmodel.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl(RecipeRemoteDataSource());
});

final favoriteRecipeIdsProvider = FutureProvider<Set<int>>((ref) async {
  final authState = ref.watch(authStateProvider);

  if (authState.valueOrNull == null) {
    return {};
  }

  final repo = ref.watch(recipeRepositoryProvider);
  final favoriteRecipes = await repo.getFavoriteRecipes(limit: 9999);
  return favoriteRecipes.map((r) => r.id!).toSet();
});

// -------------------- STATE --------------------
class HomeState {
  final bool loading;
  final String? error;
  final String search;
  // O 'category' foi removido para dar lugar ao mapa de receitas
  final Map<String, List<Recipe>> categorizedRecipes;
  final List<String> categories; // Usado para manter a ordem na UI

  const HomeState({
    this.loading = false,
    this.error,
    this.search = '',
    this.categorizedRecipes = const {},
    this.categories = const [],
  });

  HomeState copyWith({
    bool? loading,
    String? error,
    String? search,
    Map<String, List<Recipe>>? categorizedRecipes,
    List<String>? categories,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      error: error == '' ? null : (error ?? this.error),
      search: search ?? this.search,
      categorizedRecipes: categorizedRecipes ?? this.categorizedRecipes,
      categories: categories ?? this.categories,
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
      // Busca todas as receitas, aplicando o filtro de busca se houver
      final recipes = await repo.getAll(
        search: state.search.isEmpty ? null : state.search,
        // O filtro de categoria foi removido da busca principal
      );
      final favoriteIds = await ref.read(favoriteRecipeIdsProvider.future);

      final updatedRecipes = recipes.map((recipe) {
        return recipe.copyWith(isFavorite: favoriteIds.contains(recipe.id));
      }).toList();

      // Agrupa as receitas por categoria
      final newCategorizedRecipes = <String, List<Recipe>>{};
      for (final recipe in updatedRecipes) {
        (newCategorizedRecipes[recipe.category] ??= []).add(recipe);
      }

      // Cria uma lista ordenada com os nomes das categorias
      final newCategories = newCategorizedRecipes.keys.toList()..sort();

      state = state.copyWith(
        loading: false,
        categorizedRecipes: newCategorizedRecipes,
        categories: newCategories,
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

  void setSearch(String value) {
    state = state.copyWith(search: value);
    load();
  }

  // O método setCategory não é mais necessário
  // void setCategory(String? value) { ... }

  Future<void> refresh() => load();
}

// -------------------- PROVIDER --------------------
final homeVmProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  ref.watch(authStateProvider);

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