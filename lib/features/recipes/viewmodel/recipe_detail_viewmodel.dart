import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/repositories/recipe_repository.dart';
import 'home_viewmodel.dart'; // Assuming this provides recipeRepositoryProvider

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

  // Methods to update temporary edit state in ViewModel (if managing edit fields here)
  void updateTitle(String title) {
    // state = state.copyWith(editedTitle: title);
  }

  void updateTimeMinutes(String time) {
    // state = state.copyWith(editedTimeMinutes: time);
  }

  void updateServings(String servings) {
    // state = state.copyWith(editedServings: servings);
  }

  void updateIngredientsText(String ingredientsText) {
    // state = state.copyWith(editedIngredientsText: ingredientsText);
  }

  void updateStepsText(String stepsText) {
    // state = state.copyWith(editedStepsText: stepsText);
  }

  Future<void> saveRecipe() async {
    if (state.recipe == null || state.recipe!.id == null) {
      state = state.copyWith(error: "Nenhuma receita para salvar.");
      return;
    }
    // This is where you would construct the updatedRecipe from the state fields
    // that were presumably updated by updateTitle, updateTimeMinutes, etc.
    // Or, if the RecipePage is passing the complete updated Recipe object, use that.
    // For now, let's assume the RecipePage prepares the Recipe and we just need to call update.
    // A more robust implementation would involve the ViewModel building the Recipe.

    // This method is called from RecipePage after it has called individual updateX methods.
    // Those updateX methods are currently stubs.
    // The logic in RecipePage's _toggleEditMode currently prepares an updated Recipe
    // and calls this saveRecipe function, but doesn't pass the recipe.
    // This indicates a design gap to be filled: either pass recipe to saveRecipe,
    // or have updateX methods store changes in ViewModel state and saveRecipe uses that.

    // As a placeholder, we just reload. The actual update logic needs to be correctly implemented.
    print("RecipeDetailViewModel: saveRecipe() called. Actual update logic needs implementation using repo.update().");
    try {
        state = state.copyWith(loading: true, error: '');
        // Example: if state.recipe was already updated to the new values:
        // await repo.update(state.recipe!);
        // Or if RecipePage passed the updated recipe:
        // await repo.update(updatedRecipeFromPage);
        await load(); // Reload data after attempting save
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
