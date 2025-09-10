import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/domain/entities/recipe.dart';
import 'package:receitas_do_guaxininho/features/recipes/viewmodel/home_viewmodel.dart';
import 'package:receitas_do_guaxininho/main.dart';

// -------------------- STATE --------------------
class FavoriteRecipesState {
  final bool isLoading;
  final String? error;
  // Mapa para armazenar receitas por categoria
  final Map<String, List<Recipe>> categorizedRecipes;
  final List<String> categories;

  const FavoriteRecipesState({
    this.isLoading = false,
    this.error,
    this.categorizedRecipes = const {},
    this.categories = const [],
  });

  FavoriteRecipesState copyWith({
    bool? isLoading,
    String? error,
    Map<String, List<Recipe>>? categorizedRecipes,
    List<String>? categories,
  }) {
    return FavoriteRecipesState(
      isLoading: isLoading ?? this.isLoading,
      error: error == '' ? null : (error ?? this.error),
      categorizedRecipes: categorizedRecipes ?? this.categorizedRecipes,
      categories: categories ?? this.categories,
    );
  }
}

// -------------------- VIEWMODEL --------------------
class FavoriteRecipesViewModel extends StateNotifier<FavoriteRecipesState> {
  final Ref ref;

  FavoriteRecipesViewModel(this.ref) : super(const FavoriteRecipesState());

  Future<void> loadFavorites() async {
    if (state.categorizedRecipes.isNotEmpty && !state.isLoading) return;

    state = state.copyWith(isLoading: true, error: '');
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final favoriteRecipes = await repo.getFavoriteRecipes();

      if (favoriteRecipes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          categorizedRecipes: {},
          categories: [],
        );
        return;
      }

      final newCategorizedRecipes = <String, List<Recipe>>{};
      for (final recipe in favoriteRecipes) {
        (newCategorizedRecipes[recipe.category] ??= []).add(recipe);
      }

      final newCategories = newCategorizedRecipes.keys.toList()..sort();

      state = state.copyWith(
        isLoading: false,
        categorizedRecipes: newCategorizedRecipes,
        categories: newCategories,
        error: '',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// -------------------- PROVIDER --------------------
final favoriteRecipesViewModelProvider =
    StateNotifierProvider.autoDispose<
      FavoriteRecipesViewModel,
      FavoriteRecipesState
    >((ref) {
      ref.watch(authStateProvider);
      return FavoriteRecipesViewModel(ref)..loadFavorites();
    });
