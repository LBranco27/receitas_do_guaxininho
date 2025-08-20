import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/recipe.dart';
import '../viewmodel/create_recipe_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';

class CreateRecipePage extends ConsumerStatefulWidget {
  const CreateRecipePage({super.key});

  @override
  ConsumerState<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends ConsumerState<CreateRecipePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  final _category = TextEditingController(text: 'Saladas');
  final _time = TextEditingController(text: '10');
  final _servings = TextEditingController(text: '2');

  String? _imagePath;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _ingredients.dispose();
    _steps.dispose();
    _category.dispose();
    _time.dispose();
    _servings.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _imagePath = f.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRecipeVmProvider);
    final vm = ref.read(createRecipeVmProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar receita')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Selecionar imagem'),
                ),
                const SizedBox(width: 12),
                if (_imagePath != null)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_imagePath!), height: 80, fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _time,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tempo (min)'),
                    validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _servings,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pessoas'),
                    validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _desc,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ingredients,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ingredientes (1 por linha)',
                hintText: 'Ex.: 2 ovos\n1 xícara de farinha\n...',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _steps,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Modo de preparo (1 passo por linha)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.saving
                  ? null
                  : () async {
                if (!_form.currentState!.validate()) return;
                final recipe = Recipe(
                  name: _name.text.trim(),
                  description: _desc.text.trim(),
                  ingredients: _ingredients.text
                      .split('\n')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  steps: _steps.text
                      .split('\n')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  category: _category.text.trim().isEmpty
                      ? 'Outros'
                      : _category.text.trim(),
                  timeMinutes: int.tryParse(_time.text) ?? 0,
                  servings: int.tryParse(_servings.text) ?? 1,
                  imagePath: _imagePath,
                );
                final id = await vm.create(recipe);
                if (id != null && context.mounted) {
                  // recarrega a Home e navega para o detalhe criado
                  await ref.read(homeVmProvider.notifier).refresh();
                  context.go('/recipe/$id');
                }
              },
              child: state.saving
                  ? const SizedBox(
                  height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Criar receita'),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(state.error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
