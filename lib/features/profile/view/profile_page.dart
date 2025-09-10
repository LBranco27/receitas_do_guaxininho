import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receitas_do_guaxininho/features/auth/viewmodel/profile_providers.dart';
import 'package:receitas_do_guaxininho/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:receitas_do_guaxininho/features/profile/viewmodel/favorite_recipes_viewmodel.dart';
import 'package:receitas_do_guaxininho/features/profile/viewmodel/my_recipes_viewmodel.dart';
import 'package:receitas_do_guaxininho/domain/entities/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // --------- Configs do "ver mais" das categorias de favoritos ---------
  static const int _initialCategories = 2;
  static const int _previewItemsPerCategory = 2;

  int _visibleCategories = _initialCategories;
  final Map<String, bool> _expandedCategories = {};
  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCurrentUserProfile = widget.userId == null || widget.userId == currentUserId;

    final userProfileAsyncValue = isCurrentUserProfile
        ? ref.watch(userProfileProvider)
        : ref.watch(anyUserProfileProvider(widget.userId!));

    final profileViewModel = ref.watch(profileViewModelProvider);
    final favoritesState = ref.watch(favoriteRecipesViewModelProvider);
    final myRecipesState = ref.watch(myRecipesViewModelProvider(widget.userId));
    final myRecipesNotifier = ref.read(myRecipesViewModelProvider(widget.userId).notifier);

    ref.listen<AsyncValue<bool>>(profileViewModelProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
      if (!state.isLoading && state.hasValue && state.value == true && isCurrentUserProfile) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto de perfil atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUserProfile ? 'Meu Perfil' : 'Perfil'),
      ),
      body: userProfileAsyncValue.when(
        data: (profileData) {
          if (profileData == null && !isCurrentUserProfile) {
            return const Center(child: Text('Perfil não encontrado.'));
          }
          final name = profileData?['name'] as String?;
          final avatarUrl = profileData?['avatar_url'] as String?;

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // --- Cabeçalho ---
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 80, color: Colors.grey.shade600)
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                name ?? (isCurrentUserProfile ? 'Usuário' : 'Usuário Anônimo'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // --- Área do próprio usuário ---
              if (isCurrentUserProfile) ...[
                profileViewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Alterar Foto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    ref.read(profileViewModelProvider.notifier).uploadAvatar();
                  },
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 16),
                Text('Receitas Favoritas', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildCategorizedFavorites(context, favoritesState),
              ],

              // --- Minhas receitas com paginação ---
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                isCurrentUserProfile ? 'Minhas Receitas' : 'Receitas de ${name ?? "Usuário"}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Mostrando 5 receitas por página.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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

  // ---- Favoritas (categorias) com "ver mais" global e por categoria ----
  Widget _buildCategorizedFavorites(BuildContext context, FavoriteRecipesState state) {
    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.categories.isEmpty) {
      return Center(child: Text('Erro: ${state.error}'));
    }
    if (state.categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Você ainda não favoritou nenhuma receita. 😕', textAlign: TextAlign.center),
        ),
      );
    }

    // Limita quantas categorias aparecem de uma vez
    final totalCats = state.categories.length;
    final showingCats = state.categories.take(_visibleCategories).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lista de categorias visíveis
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: showingCats.length,
          itemBuilder: (context, index) {
            final category = showingCats[index];
            final allItems = state.categorizedRecipes[category] ?? const <Recipe>[];

            final expanded = _expandedCategories[category] ?? false;
            final visibleItems = expanded
                ? allItems
                : allItems.take(_previewItemsPerCategory).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho da categoria com botão "ver mais/menos"
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      if (allItems.length > _previewItemsPerCategory)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _expandedCategories[category] = !expanded;
                            });
                          },
                          icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                          label: Text(expanded ? 'Ver menos' : 'Ver mais'),
                        ),
                    ],
                  ),
                ),

                // Receitas visíveis da categoria
                ...visibleItems.map((r) => _buildRecipeCard(context, r)).toList(),

                const Divider(height: 32),
              ],
            );
          },
        ),

        // "Ver mais categorias" global
        if (_visibleCategories < totalCats)
          Align(
            alignment: Alignment.center,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _visibleCategories =
                      (_visibleCategories + _initialCategories).clamp(0, totalCats);
                });
              },
              icon: const Icon(Icons.category),
              label: Text('Ver mais categorias (${totalCats - _visibleCategories})'),
            ),
          ),

        // "Ver menos categorias" global
        if (_visibleCategories > _initialCategories)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _visibleCategories = _initialCategories;
                });
              },
              icon: const Icon(Icons.expand_less),
              label: const Text('Ver menos categorias'),
            ),
          ),
      ],
    );
  }

  // ---- Minhas receitas (paginação por botões) ----
  Widget _buildPaginatedMyRecipes(
      BuildContext context,
      MyRecipesState state,
      MyRecipesViewModel notifier,
      ) {
    if (state.isLoading && state.recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.recipes.isEmpty) {
      return Column(
        children: [
          Text('Erro: ${state.error}', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            onPressed: () => notifier.loadPage(state.page),
          ),
        ],
      );
    }
    if (state.recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.userId == null
                ? 'Você ainda não criou nenhuma receita. ✍️'
                : 'Este usuário ainda não criou nenhuma receita. 😕',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        // lista da página corrente (5 itens)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.recipes.length,
          itemBuilder: (context, index) {
            final recipe = state.recipes[index];
            return _buildRecipeCard(context, recipe);
          },
        ),
        const SizedBox(height: 12),

        // controles de paginação
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
              onPressed: (!state.isLoading && state.page > 0)
                  ? () => notifier.prevPage()
                  : null,
            ),
            Text(
              'Página ${state.page + 1}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.chevron_right),
              label: const Text('Próxima'),
              onPressed: (!state.isLoading && state.hasMore)
                  ? () => notifier.nextPage()
                  : null,
            ),
          ],
        ),

        if (state.isLoading) ...[
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  // ---- Card de receita ----
  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    final img = (recipe.imagePath?.trim().isEmpty ?? true) ? null : recipe.imagePath;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/recipe/${recipe.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: img != null
                    ? Image.network(
                  img,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ),
                  errorBuilder: (context, error, stack) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu_outlined, color: Colors.grey),
                  ),
                )
                    : Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(Icons.restaurant_menu_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${recipe.timeMinutes} min • ${recipe.category}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
