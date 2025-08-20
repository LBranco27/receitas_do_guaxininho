import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/recipe_local_datasource.dart';
import '../../../data/repositories/recipe_repository_impl.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/repositories/recipe_repository.dart';

/// Provider do repositório (DI). Override em main.dart para trocar implementações.
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl(RecipeLocalDataSource());
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
  HomeViewModel(this.repo) : super(const HomeState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: '');
    try {
      final list = await repo.getAll(
        search: state.search.isEmpty ? null : state.search,
        category: state.category,
      );
      state = state.copyWith(loading: false, recipes: list);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
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

// provider para a tela
final homeVmProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  final vm = HomeViewModel(repo);
  vm.load();
  return vm;
});
