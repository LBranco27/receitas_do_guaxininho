import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receitas_do_guaxininho/features/auth/viewmodel/profile_providers.dart';
import 'package:receitas_do_guaxininho/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:receitas_do_guaxininho/features/profile/viewmodel/favorite_recipes_viewmodel.dart';
import 'package:receitas_do_guaxininho/features/profile/viewmodel/my_recipes_viewmodel.dart';
import 'package:receitas_do_guaxininho/domain/entities/recipe.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final profileViewModel = ref.watch(profileViewModelProvider);
    final favoritesState = ref.watch(favoriteRecipesViewModelProvider);
    final favoritesNotifier = ref.read(favoriteRecipesViewModelProvider.notifier);
    final myRecipesState = ref.watch(myRecipesViewModelProvider);
    final myRecipesNotifier = ref.read(myRecipesViewModelProvider.notifier);

    ref.listen<AsyncValue<bool>>(profileViewModelProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      if (!state.isLoading && state.hasValue && state.value == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto de perfil atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: userProfile.when(
        data: (profile) {
          final name = profile?['name'] as String?;
          final avatarUrl = profile?['avatar_url'] as String?;

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24.0),
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person,
                    size: 80, color: Colors.grey.shade600)
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                name ?? 'Usuário',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              profileViewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Alterar Foto'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  ref
                      .read(profileViewModelProvider.notifier)
                      .uploadAvatar();
                },
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),

              Text(
                'Receitas Favoritas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              _buildPaginatedFavorites(context, favoritesState, favoritesNotifier),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),

              Text(
                'Minhas Receitas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              _buildPaginatedMyRecipes(context, myRecipesState, myRecipesNotifier),

              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erro ao carregar perfil: $e')),
      ),
    );
  }

  Widget _buildPaginatedFavorites(BuildContext context, FavoriteRecipesState state, FavoriteRecipesViewModel notifier) {
    if (state.isLoading && state.recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.recipes.isEmpty) {
      return Center(child: Text('Erro: ${state.error}'));
    }

    if (state.recipes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Você ainda não favoritou nenhuma receita. 😕',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (state.isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ))
        else
          ...state.recipes.map((recipe) => _buildRecipeCard(context, recipe)),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
              onPressed: state.page == 0 ? null : () {
                notifier.loadPage(state.page - 1);
              },
            ),

            Text('Página ${state.page + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),

            TextButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Próxima'),
              onPressed: !state.hasMore ? null : () {
                notifier.loadPage(state.page + 1);
              },
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPaginatedMyRecipes(BuildContext context, MyRecipesState state, MyRecipesViewModel notifier) {
    if (state.isLoading && state.recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.recipes.isEmpty) {
      return Center(child: Text('Erro: ${state.error}'));
    }

    if (state.recipes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Você ainda não criou nenhuma receita. ✍️',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (state.isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ))
        else
          ...state.recipes.map((recipe) => _buildRecipeCard(context, recipe)),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
              onPressed: state.page == 0 ? null : () {
                notifier.loadPage(state.page - 1);
              },
            ),

            Text('Página ${state.page + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),

            TextButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Próxima'),
              onPressed: !state.hasMore ? null : () {
                notifier.loadPage(state.page + 1);
              },
            ),
          ],
        )
      ],
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: recipe.imagePath != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            recipe.imagePath!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const Icon(Icons.restaurant),
          ),
        )
            : const Icon(Icons.restaurant, size: 40),
        title: Text(recipe.name),
        subtitle: Text('${recipe.timeMinutes} min • ${recipe.category}'),
        onTap: () {
          context.push('/recipe/${recipe.id}');
        },
      ),
    );
  }
}