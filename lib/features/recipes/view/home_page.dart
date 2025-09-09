import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          FutureBuilder<List<String>>(
            future: ref.read(recipeRepositoryProvider).getCategories(),
            builder: (context, snap) {
              final cats = ['Todas', ...?snap.data];
              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (_, i) {
                    final label = cats[i];
                    final selected = (state.category ?? 'Todas') == label;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) =>
                          vm.setCategory(label == 'Todas' ? null : label),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: cats.length,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? Center(child: Text('Erro: ${state.error}'))
                : RefreshIndicator(
              onRefresh: vm.refresh,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .80,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: state.recipes.length,
                itemBuilder: (_, i) {
                  final r = state.recipes[i];
                  return RecipeCard(
                    title: r.name,
                    subtitle: '${r.timeMinutes} min • ${r.servings} pessoas',
                    imagePath: r.imagePath,
                    favorite: r.isFavorite,
                    onTap: () => context.push('/recipe/${r.id}'),
                    onFavoriteToggle: () {
                      vm.toggleFavorite(r.id!, r.isFavorite);
                    },
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

