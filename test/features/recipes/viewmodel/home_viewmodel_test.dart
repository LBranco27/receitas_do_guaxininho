import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receitas_do_guaxininho/domain/entities/recipe.dart';
import 'package:receitas_do_guaxininho/domain/repositories/recipe_repository.dart';
import 'package:receitas_do_guaxininho/features/recipes/viewmodel/home_viewmodel.dart';

class FakeRecipeRepository implements RecipeRepository {
  final List<Recipe> _allRecipes;
  final List<Recipe> _popularRecipes;
  bool shouldThrowError;

  FakeRecipeRepository({
    required List<Recipe> allRecipes,
    required List<Recipe> popularRecipes,
    this.shouldThrowError = false,
  })  : _allRecipes = allRecipes,
        _popularRecipes = popularRecipes;

  @override
  Future<List<Recipe>> getAll({String? search, String? category}) async {
    if (shouldThrowError) throw Exception('Falha na rede');
    if (search != null && search.isNotEmpty) {
      return _allRecipes
          .where((r) => r.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    return _allRecipes;
  }

  @override
  Future<List<Recipe>> getPopularRecipes({int limit = 10}) async {
    if (shouldThrowError) throw Exception('Falha na rede');
    return _popularRecipes;
  }

  @override
  Future<void> addFavorite(int recipeId) async {}

  @override
  Future<int?> create(Recipe recipe) async => null;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<Recipe?> getById(int id) async => null;

  @override
  Future<List<String>> getCategories() async => [];

  @override
  Future<List<Recipe>> getFavoriteRecipes({int page = 0, int limit = 10}) async => [];

  @override
  Future<List> getFromCategory(String category) async => [];

  @override
  Future<List<Recipe>> getMyRecipes({int page = 0, int limit = 10}) async => [];

  @override
  Future<List<Recipe>> getUserRecipes({required String userId, required int page, required int limit}) async => [];

  @override
  Future<void> removeFavorite(int recipeId) async {}

  @override
  Future<Recipe> update(Recipe recipe) async => recipe;
}

void main() {
  // Dados de exemplo
  final mockRecipes = [
    Recipe(
      id: 1,
      name: 'Bolo de Chocolate',
      category: 'Sobremesas',
      description: '',
      owner: 'a',
      ingredients: {},
      steps: [],
      timeMinutes: 60,
      servings: 8,
    ),
    Recipe(
      id: 2,
      name: 'Frango Assado',
      category: 'Aves',
      description: '',
      owner: 'b',
      ingredients: {},
      steps: [],
      timeMinutes: 90,
      servings: 4,
    ),
    Recipe(
      id: 3,
      name: 'Pudim de Leite',
      category: 'Sobremesas',
      description: '',
      owner: 'c',
      ingredients: {},
      steps: [],
      timeMinutes: 50,
      servings: 6,
    ),
  ];
  final mockPopularRecipes = [ /* Pudim */
    Recipe(
      id: 3,
      name: 'Pudim de Leite',
      category: 'Sobremesas',
      description: '',
      owner: 'c',
      ingredients: {},
      steps: [],
      timeMinutes: 50,
      servings: 6,
    ),
  ];

  group('HomeViewModel Tests', () {
    test('Deve carregar e agrupar receitas com sucesso', () async {
      // ARRANGE
      final container = ProviderContainer(
        overrides: [
          // Provider -> overrideWithValue
          recipeRepositoryProvider.overrideWithValue(
            FakeRecipeRepository(
              allRecipes: mockRecipes,
              popularRecipes: mockPopularRecipes,
            ),
          ),
          // FutureProvider<List<String>> -> overrideWith
          categoriesProvider.overrideWith((ref) => ['Sobremesas', 'Aves']),
          // FutureProvider<Set<int>> -> overrideWith
          favoriteRecipeIdsProvider.overrideWith((ref) => {3}),
        ],
      );
      addTearDown(container.dispose);

      final viewModel = container.read(homeVmProvider.notifier);

      // ACT
      await viewModel.load();

      // ASSERT
      final state = container.read(homeVmProvider);
      expect(state.loading, isFalse);
      expect(state.categorizedRecipes.length, 2);
      expect(state.categorizedRecipes['Sobremesas']?.length, 2);
      expect(state.popularRecipes.first.name, 'Pudim de Leite');
      expect(state.popularRecipes.first.isFavorite, isTrue);
    });

    test('Deve atualizar o estado de erro quando o repositório falha', () async {
      // ARRANGE
      final container = ProviderContainer(
        overrides: [
          recipeRepositoryProvider.overrideWithValue(
            FakeRecipeRepository(
              allRecipes: [],
              popularRecipes: [],
              shouldThrowError: true, // Força o repositório a dar erro
            ),
          ),
          categoriesProvider.overrideWith((ref) => []),
          favoriteRecipeIdsProvider.overrideWith((ref) => <int>{}),
        ],
      );
      addTearDown(container.dispose);

      final viewModel = container.read(homeVmProvider.notifier);

      // ACT
      await viewModel.load();

      // ASSERT
      final state = container.read(homeVmProvider);
      expect(state.loading, isFalse);
      expect(state.error, isNotNull);
      expect(state.error, contains('Falha na rede'));
    });

    test('Deve filtrar as receitas ao usar a busca (setSearch)', () async {
      // ARRANGE
      final container = ProviderContainer(
        overrides: [
          recipeRepositoryProvider.overrideWithValue(
            FakeRecipeRepository(
              allRecipes: mockRecipes,
              popularRecipes: mockPopularRecipes,
            ),
          ),
          categoriesProvider.overrideWith((ref) => ['Sobremesas', 'Aves']),
          favoriteRecipeIdsProvider.overrideWith((ref) => {3}),
        ],
      );
      addTearDown(container.dispose);

      final viewModel = container.read(homeVmProvider.notifier);
      await viewModel.load(); // Carga inicial

      // ACT
      await viewModel.setSearch('Bolo');

      // ASSERT
      final state = container.read(homeVmProvider);
      expect(state.categorizedRecipes.length, 1);
      expect(state.categorizedRecipes.containsKey('Sobremesas'), isTrue);
      expect(state.categorizedRecipes['Sobremesas']!.first.name, 'Bolo de Chocolate');
    });
  });
}
