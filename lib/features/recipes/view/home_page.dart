import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/recipe.dart';
import '../../auth/viewmodel/login_viewmodel.dart';
import '../../auth/viewmodel/profile_providers.dart';
import '../../profile/viewmodel/favorite_recipes_viewmodel.dart';
import '../../profile/viewmodel/my_recipes_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';
import 'widgets/recipe_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    // Adiciona um listener para mostrar/esconder o botão 'X'
    _searchController.addListener(() {
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    _searchController.text = query;
    _searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
    ref.read(homeVmProvider.notifier).setSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(homeVmProvider.notifier);
    final state = ref.watch(homeVmProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: userProfile.when(
          data: (profile) {
            final name = profile?['name'] as String?;
            final avatarUrl = profile?['avatar_url'] as String?;

            return Row(
              children: [
                InkWell(
                  onTap: () => context.push('/profile'),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(name != null ? 'Olá, $name' : 'Receitas'),
              ],
            );
          },
          loading: () => const Text('Carregando...'),
          error: (_, __) => const Text('Receitas'),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/create'),
            icon: const Icon(Icons.add),
            tooltip: 'Nova receita',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar Saída'),
                  content: const Text('Você tem certeza que deseja sair?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authRepositoryProvider).signOut();
                ref.invalidate(favoriteRecipeIdsProvider);
                ref.invalidate(favoriteRecipesViewModelProvider);
                ref.invalidate(myRecipesViewModelProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              onChanged: vm.setSearch,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou categoria...',
                prefixIcon: const Icon(Icons.search),
                // ## INÍCIO DA ALTERAÇÃO ##
                // Adiciona o botão 'X' (sufixo) apenas se houver texto
                suffixIcon: _showClearButton
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // O onChanged já é acionado ao limpar,
                    // então a busca será atualizada automaticamente.
                  },
                )
                    : null,
                // ## FIM DA ALTERAÇÃO ##
              ),
            ),
          ),
          _CategoryChips(
            categories: state.allAvailableCategories,
            onCategorySelected: _performSearch,
          ),
          Expanded(
            child: state.loading && state.categorizedRecipes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? Center(child: Text('Erro: ${state.error}'))
                : state.categories.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  state.search.isEmpty
                      ? 'Nenhuma receita encontrada.'
                      : 'Nenhum resultado para "${state.search}"',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: state.categories.length,
                itemBuilder: (_, i) {
                  final category = state.categories[i];
                  final recipes =
                  state.categorizedRecipes[category]!;
                  return _CategoryCarousel(
                    category: category,
                    recipes: recipes,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCarousel extends ConsumerWidget {
  final String category;
  final List<Recipe> recipes;

  const _CategoryCarousel({
    required this.category,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(homeVmProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            category,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final r = recipes[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: RecipeCard(
                  title: r.name,
                  subtitle: '${r.timeMinutes} min • ${r.servings} pessoas',
                  imagePath: r.imagePath,
                  favorite: r.isFavorite,
                  onTap: () => context.push('/recipe/${r.id}'),
                  onFavoriteToggle: () {
                    vm.toggleFavorite(r.id!, r.isFavorite);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final Function(String) onCategorySelected;
  static const int _maxVisibleChips = 3;

  const _CategoryChips({
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleChips = categories.take(_maxVisibleChips).toList();
    final hiddenChips = categories.skip(_maxVisibleChips).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          ...visibleChips.map((category) => _buildChip(context, category)),
          if (hiddenChips.isNotEmpty) _buildMoreChip(context, hiddenChips),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: () => onCategorySelected(label),
        backgroundColor:
        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        side: BorderSide(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildMoreChip(BuildContext context, List<String> hiddenCategories) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: const Text('... mais'),
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.4,
                minChildSize: 0.3,
                maxChildSize: 0.6,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: hiddenCategories.length,
                          itemBuilder: (context, index) {
                            final category = hiddenCategories[index];
                            return ListTile(
                              title: Center(child: Text(category)),
                              onTap: () {
                                Navigator.of(context).pop();
                                onCategorySelected(category);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        backgroundColor:
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
      ),
    );
  }
}