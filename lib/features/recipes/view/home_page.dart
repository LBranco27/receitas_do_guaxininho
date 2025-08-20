import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/home_viewmodel.dart';
import 'widgets/recipe_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(homeVmProvider.notifier);
    // Call refresh when the widget is built to ensure data is fresh.
    // Consider if this should be more targeted based on lifecycle events or specific actions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.refresh();
    });

    final state = ref.watch(homeVmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        actions: [
          IconButton(
            onPressed: () => context.push('/create'),
            icon: const Icon(Icons.add),
            tooltip: 'Nova receita',
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
            future: ref.read(recipeRepositoryProvider).getCategories(), // Assuming recipeRepositoryProvider is accessible
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
                  childAspectRatio: .78,
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
