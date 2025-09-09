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
  final Map<String, List<Recipe>> categorizedRecipes;
  final List<String> categories;
  final List<String> allAvailableCategories;

  const HomeState({
    this.loading = false,
    this.error,
    this.search = '',
    this.categorizedRecipes = const {},
    this.categories = const [],
    this.allAvailableCategories = const [],
  });

  HomeState copyWith({
    bool? loading,
    String? error,
    String? search,
    Map<String, List<Recipe>>? categorizedRecipes,
    List<String>? categories,
    List<String>? allAvailableCategories,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      error: error == '' ? null : (error ?? this.error),
      search: search ?? this.search,
      categorizedRecipes: categorizedRecipes ?? this.categorizedRecipes,
      categories: categories ?? this.categories,
      allAvailableCategories:
      allAvailableCategories ?? this.allAvailableCategories,
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
      // Usa a lista de categorias do novo provider estático
      final allCats = ref.read(categoriesProvider);
      state = state.copyWith(allAvailableCategories: allCats);

      final recipes = await repo.getAll(
        search: state.search.isEmpty ? null : state.search,
      );
      final favoriteIds = await ref.read(favoriteRecipeIdsProvider.future);

      final updatedRecipes = recipes.map((recipe) {
        return recipe.copyWith(isFavorite: favoriteIds.contains(recipe.id));
      }).toList();

      final newCategorizedRecipes = <String, List<Recipe>>{};
      for (final recipe in updatedRecipes) {
        (newCategorizedRecipes[recipe.category] ??= []).add(recipe);
      }

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

// O provider agora é síncrono и retorna uma lista fixa de categorias.
final categoriesProvider = Provider<List<String>>((ref) {
  return [
    'Acompanhamentos',
    'Aperitivos',
    'Arroz e Risotos',
    'Aves',
    'Bebidas',
    'Bolos e Tortas',
    'Brasileira',
    'Carnes',
    'Churrasco',
    'Fitness',
    'Frutos do Mar',
    'Italiana',
    'Japonesa',
    'Chinesa',
    'Lanches',
    'Massas',
    'Mexicana',
    'Molhos',
    'Pães',
    'Peixes',
    'Rápida e Fácil',
    'Saladas',
    'Sopas',
    'Sobremesas',
    'Vegana',
    'Vegetariana',
    'Árabe',
  ]..sort();
});
