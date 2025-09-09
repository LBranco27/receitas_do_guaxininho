import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/recipe.dart'; // Adicionado para usar o tipo Recipe
import '../../auth/viewmodel/login_viewmodel.dart';
import '../../auth/viewmodel/profile_providers.dart';
import '../../profile/viewmodel/favorite_recipes_viewmodel.dart';
import '../../profile/viewmodel/my_recipes_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';
import 'widgets/recipe_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: vm.setSearch,
              decoration: const InputDecoration(
                hintText: 'Buscar receita...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // O FutureBuilder com os ChoiceChips foi removido
          const SizedBox(height: 8),
          Expanded(
            child: state.loading && state.categorizedRecipes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? Center(child: Text('Erro: ${state.error}'))
                : state.categories.isEmpty // Checa se há categorias para exibir
                ? Center(
              child: Text(
                state.search.isEmpty
                    ? 'Nenhuma receita encontrada.'
                    : 'Nenhum resultado para "${state.search}"',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
                : RefreshIndicator(
              onRefresh: vm.refresh,
              // O GridView foi substituído por um ListView
              child: ListView.builder(
                // O padding foi movido do GridView para o ListView
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: state.categories.length,
                itemBuilder: (_, i) {
                  final category = state.categories[i];
                  final recipes = state.categorizedRecipes[category]!;
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

// Widget auxiliar para renderizar cada carrossel de categoria
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
          // Adiciona um espaçamento vertical entre os carrosséis
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0, left: 4.0),
          child: Text(
            category,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(
          height: 230, // Altura fixa para a área do carrossel
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final r = recipes[index];
              return Container(
                // Define uma largura para os cards dentro do carrossel
                width: 180,
                // Mantém o espaçamento entre os cards
                margin: const EdgeInsets.only(right: 12),
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