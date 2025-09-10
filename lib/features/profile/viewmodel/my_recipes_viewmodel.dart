import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/domain/entities/recipe.dart';
import 'package:receitas_do_guaxininho/domain/repositories/recipe_repository.dart';
import 'package:receitas_do_guaxininho/main.dart';
import '../../recipes/viewmodel/home_viewmodel.dart';

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
  final String? userId;

  static const _pageSize = 5;

  MyRecipesViewModel(this.ref, this.userId) : super(const MyRecipesState()) {
    loadInitial();
  }

  Future<void> loadInitial() {
    if (state.recipes.isEmpty) {
      return loadPage(0);
    }
    return Future.value();
  }

  Future<void> loadPage(int page) async {
    if (state.isLoading) return;

    if (kDebugMode) {
      print('[MyRecipesViewModel] Solicitando página: $page');
    }

    state = state.copyWith(isLoading: true, error: '');

    try {
      final repo = ref.read(recipeRepositoryProvider);
      final List<Recipe> pageRecipes;

      if (userId != null) {
        pageRecipes = await repo.getUserRecipes(
          userId: userId!,
          page: page,
          limit: _pageSize,
        );
      } else {
        pageRecipes = await repo.getMyRecipes(page: page, limit: _pageSize);
      }

      if (kDebugMode) {
        print(
          '[MyRecipesViewModel] Recebidas ${pageRecipes.length} receitas na página $page.',
        );
      }

      state = state.copyWith(
        isLoading: false,
        recipes: pageRecipes,
        page: page,
        hasMore: pageRecipes.length == _pageSize,
        error: '',
      );

      if (kDebugMode) {
        print(
          '[MyRecipesViewModel] Estado atualizado. Página: ${state.page}, '
          'Qtd itens na página: ${state.recipes.length}, HasMore: ${state.hasMore}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MyRecipesViewModel] Erro ao carregar página $page: $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: page == 0 ? state.hasMore : false,
      );
    }
  }

  void nextPage() {
    if (!state.isLoading && state.hasMore) {
      loadPage(state.page + 1);
    }
  }

  /// Voltar para a página anterior (se possível).
  void prevPage() {
    if (!state.isLoading && state.page > 0) {
      loadPage(state.page - 1);
    }
  }
}

final myRecipesViewModelProvider =
    StateNotifierProvider.family<MyRecipesViewModel, MyRecipesState, String?>((
      ref,
      userId,
    ) {
      if (userId == null) {
        ref.watch(authStateProvider);
      }
      return MyRecipesViewModel(ref, userId);
    });
