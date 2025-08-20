import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/repositories/recipe_repository.dart';
import 'home_viewmodel.dart';

class RecipeDetailState {
  final bool loading;
  final String? error;
  final Recipe? recipe;
  const RecipeDetailState({this.loading = false, this.error, this.recipe});

  RecipeDetailState copyWith({bool? loading, String? error, Recipe? recipe}) =>
      RecipeDetailState(
        loading: loading ?? this.loading,
        error: error == '' ? null : (error ?? this.error),
        recipe: recipe ?? this.recipe,
      );
}

class RecipeDetailViewModel extends StateNotifier<RecipeDetailState> {
  final RecipeRepository repo;
  final int id;

  RecipeDetailViewModel(this.repo, this.id)
      : super(const RecipeDetailState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: '');
    try {
      final r = await repo.getById(id);
      state = state.copyWith(loading: false, recipe: r);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> toggleFavorite() async {
    final r = state.recipe;
    if (r == null) return;
    await repo.toggleFavorite(r.id!, !r.isFavorite);
    await load();
  }
}

final recipeDetailVmProvider =
StateNotifierProvider.family<RecipeDetailViewModel, RecipeDetailState, int>(
        (ref, id) {
      final repo = ref.watch(recipeRepositoryProvider);
      final vm = RecipeDetailViewModel(repo, id)..load();
      return vm;
    });
