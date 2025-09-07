import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/domain/entities/recipe.dart';
import 'package:receitas_do_guaxininho/features/recipes/viewmodel/home_viewmodel.dart';

// -------------------- STATE --------------------
class FavoriteRecipesState {
  final bool isLoading;
  final String? error;
  final List<Recipe> recipes;
  final int page;
  final bool hasMore;

  const FavoriteRecipesState({
    this.isLoading = false,
    this.error,
    this.recipes = const [],
    this.page = 0,
    this.hasMore = true,
  });

  FavoriteRecipesState copyWith({
    bool? isLoading,
    String? error,
    List<Recipe>? recipes,
    int? page,
    bool? hasMore,
  }) {
    return FavoriteRecipesState(
      isLoading: isLoading ?? this.isLoading,
      error: error == '' ? null : (error ?? this.error),
      recipes: recipes ?? this.recipes,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// -------------------- VIEWMODEL --------------------
class FavoriteRecipesViewModel extends StateNotifier<FavoriteRecipesState> {
  final Ref ref;
  static const _pageSize = 10;

  FavoriteRecipesViewModel(this.ref) : super(const FavoriteRecipesState());

  Future<void> loadInitial() async {
    if (state.recipes.isEmpty) {
      await loadPage(0);
    }
  }

  Future<void> loadPage(int page) async {
    if (page < 0) return;

    state = state.copyWith(isLoading: true, error: '');
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final newRecipes = await repo.getFavoriteRecipes(page: page, limit: _pageSize);

      state = state.copyWith(
        isLoading: false,
        recipes: newRecipes,
        page: page,
        hasMore: newRecipes.length == _pageSize,
        error: '',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// -------------------- PROVIDER --------------------
final favoriteRecipesViewModelProvider =
StateNotifierProvider<FavoriteRecipesViewModel, FavoriteRecipesState>((ref) {
  return FavoriteRecipesViewModel(ref)..loadInitial();
});

