import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/repositories/recipe_repository.dart';
import 'home_viewmodel.dart';
import '../../profile/viewmodel/favorite_recipes_viewmodel.dart'; // Assuming this provides recipeRepositoryProvider

class RecipeDetailState {
  final bool loading;
  final String? error;
  final Recipe? recipe;

  const RecipeDetailState({
    this.loading = false,
    this.error,
    this.recipe,
  });

  RecipeDetailState copyWith({
    bool? loading,
    String? error,
    Recipe? recipe,
  }) =>
      RecipeDetailState(
        loading: loading ?? this.loading,
        error: error == '' ? null : (error ?? this.error),
        recipe: recipe ?? this.recipe,
      );
}

class RecipeDetailViewModel extends StateNotifier<RecipeDetailState> {
  final RecipeRepository repo;
  final int id;
  final Ref ref;

  RecipeDetailViewModel(this.repo, this.id, this.ref)
      : super(const RecipeDetailState());

  void updateFavoriteState(bool isFavorite) {
    if (state.recipe != null && state.recipe!.isFavorite != isFavorite) {
      state = state.copyWith(
        recipe: state.recipe!.copyWith(isFavorite: isFavorite),
      );
    }
  }

  Future<void> toggleFavorite() async {
    if (state.recipe == null) return;

    final isCurrentlyFavorite = state.recipe!.isFavorite;

    try {
      if (isCurrentlyFavorite) {
        await repo.removeFavorite(id);
      } else {
        await repo.addFavorite(id);
      }
      ref.invalidate(favoriteRecipeIdsProvider);
      ref.invalidate(favoriteRecipesViewModelProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      ref.invalidate(favoriteRecipeIdsProvider);
    }
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: '');
    try {
      final recipe = await repo.getById(id);

      if (recipe == null) {
        throw Exception("Receita não encontrada.");
      }

      final favoriteIds = await ref.read(favoriteRecipeIdsProvider.future);
      final updatedRecipe = recipe.copyWith(
        isFavorite: favoriteIds.contains(recipe.id),
      );
      state = state.copyWith(loading: false, recipe: updatedRecipe);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> saveRecipe(Recipe updatedRecipe) async {
    if (state.recipe == null) {
      state = state.copyWith(error: "Receita original não encontrada para salvar.");
      return;
    }

    state = state.copyWith(loading: true, error: '');
    try {
      await repo.update(updatedRecipe);

      state = state.copyWith(loading: false, recipe: updatedRecipe);

      ref.invalidate(homeVmProvider);
    } catch (e) {
      state = state.copyWith(loading: false, error: "Erro ao salvar receita: ${e.toString()}");
    }
  }

  Future<void> deleteCurrentRecipe() async {
    if (state.recipe == null || state.recipe!.id == null) {
      state = state.copyWith(error: "Nenhuma receita para excluir ou ID da receita ausente.");
      return;
    }
    try {
      state = state.copyWith(loading: true, error: ''); // Clear previous error
      await repo.delete(state.recipe!.id!);
      // Recipe deleted successfully. Clear it from state.
      state = state.copyWith(loading: false, recipe: null, error: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: "Erro ao excluir receita: ${e.toString()}");
    }
  }
}

final recipeDetailVmProvider =
StateNotifierProvider.family<RecipeDetailViewModel, RecipeDetailState, int>(
        (ref, id) {
      final repo = ref.watch(recipeRepositoryProvider);
      final vm = RecipeDetailViewModel(repo, id, ref)
        ..load();

      ref.listen(favoriteRecipeIdsProvider, (previous, next) {
        if (next.hasValue) {
          vm.updateFavoriteState(next.value!.contains(id));
        }
      });

      return vm;
    });
