import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/domain/entities/recipe.dart';
import 'package:receitas_do_guaxininho/domain/repositories/recipe_repository.dart'; // Assuming this is where your RecipeRepository interface is
import 'package:receitas_do_guaxininho/main.dart';

import '../../recipes/viewmodel/home_viewmodel.dart'; // For authStateProvider & recipeRepositoryProvider

class MyRecipesState {
  final bool isLoading;
  final String? error;
  final List<Recipe> recipes;
  final int page;
  final bool hasMore;

  const MyRecipesState({
    this.isLoading = false,
    this.error,
    this.recipes = const [],
    this.page = 0,
    this.hasMore = true,
  });

  MyRecipesState copyWith({
    bool? isLoading,
    String? error,
    List<Recipe>? recipes,
    int? page,
    bool? hasMore,
  }) {
    return MyRecipesState(
      isLoading: isLoading ?? this.isLoading,
      error: error == '' ? null : (error ?? this.error),
      recipes: recipes ?? this.recipes,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class MyRecipesViewModel extends StateNotifier<MyRecipesState> {
  final Ref ref;
  final String? userId; // User ID for fetching recipes, null for current user
  static const _pageSize = 5;

  MyRecipesViewModel(this.ref, this.userId) : super(const MyRecipesState());

  Future<void> loadInitial() async {
    // Only load initial if recipes are empty, to prevent multiple loads if provider is re-watched
    if (state.recipes.isEmpty) {
      await loadPage(0);
    }
  }

  Future<void> loadPage(int page) async {
    if (page < 0) return; // Do not load negative pages

    state = state.copyWith(isLoading: true, error: '');
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final List<Recipe> newRecipes;

      print("ZASZASZASsdasd");
      print(userId);
      if (userId != null) {
        newRecipes = await repo.getUserRecipes(userId: userId!, page: page, limit: _pageSize);
        print(newRecipes);
      } else {
        newRecipes = await repo.getMyRecipes(page: page, limit: _pageSize);
        print(newRecipes);
      }

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

final myRecipesViewModelProvider =
    StateNotifierProvider.family<MyRecipesViewModel, MyRecipesState, String?>((ref, userId) {
  if (userId == null) {
    ref.watch(authStateProvider);
  }
  return MyRecipesViewModel(ref, userId)..loadInitial();
});