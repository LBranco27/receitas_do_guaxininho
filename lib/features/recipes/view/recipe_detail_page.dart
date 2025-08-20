import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/recipe_detail_viewmodel.dart';

class RecipeDetailPage extends ConsumerWidget {
  final int id;
  const RecipeDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeDetailVmProvider(id));
    final vm = ref.read(recipeDetailVmProvider(id).notifier);

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null) {
      return Scaffold(body: Center(child: Text('Erro: ${state.error}')));
    }
    final r = state.recipe;
    if (r == null) {
      return const Scaffold(body: Center(child: Text('Receita não encontrada')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          IconButton(
            onPressed: vm.toggleFavorite,
            icon: Icon(r.isFavorite ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (r.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(r.imagePath!), fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Text('${r.timeMinutes} min • ${r.servings} pessoas • ${r.category}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(r.description),
          const SizedBox(height: 16),
          Text('Ingredientes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          ...r.ingredients.map((i) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check),
            title: Text(i),
          )),
          const SizedBox(height: 12),
          Text('Modo de preparo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          ...r.steps.asMap().entries.map(
                (e) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 12,
                child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(e.value),
            ),
          ),
        ],
      ),
    );
  }
}
