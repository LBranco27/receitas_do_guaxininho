import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/viewmodel/profile_providers.dart';
import '../../../domain/entities/recipe.dart';
import '../viewmodel/create_recipe_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';

class CreateRecipePage extends ConsumerStatefulWidget {
  const CreateRecipePage({super.key});

  @override
  ConsumerState<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends ConsumerState<CreateRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  final _timeMinutes = TextEditingController();
  final _servings = TextEditingController();
  XFile? _imageFile;

  String? _selectedCategory;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _ingredients.dispose();
    _steps.dispose();
    _timeMinutes.dispose();
    _servings.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(createRecipeVmProvider.notifier);
    final theme = Theme.of(context);
    final userProfile = ref.watch(userProfileProvider);

    // Agora é AsyncValue<List<String>>
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Receita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: categoriesAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Erro ao carregar categorias: $e',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
            ),
            data: (categories) {
              final dropdownValue =
              (categories.contains(_selectedCategory)) ? _selectedCategory : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nome da Receita'),
                    validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 2,
                    validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _ingredients,
                    decoration: const InputDecoration(
                      labelText: 'Ingredientes',
                      hintText:
                      'Ex.:\nLegumes:\n  1 cenoura\n  1 abobrinha\nCarnes:\n  200g de patinho moído\nTempero Geral:',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 7,
                    validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _steps,
                    decoration: const InputDecoration(
                        labelText: 'Modo de Preparo',
                        hintText: 'Passo 1\nPasso 2\n...'),
                    maxLines: 7,
                    validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16.0),

                  // ---- Dropdown de Categoria (agora com dados do AsyncValue) ----
                  DropdownButtonFormField<String>(
                    value: dropdownValue,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    hint: const Text('Selecione uma categoria'),
                    items: categories
                        .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Selecione uma categoria' : null,
                  ),

                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _timeMinutes,
                          decoration:
                          const InputDecoration(labelText: 'Tempo (min)'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _servings,
                          decoration:
                          const InputDecoration(labelText: 'Porções'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _imageFile == null
                      ? OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Selecionar Imagem'),
                    onPressed: _pickImage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                      : Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_imageFile!.path),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      TextButton(
                        child: const Text('Trocar imagem'),
                        onPressed: _pickImage,
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Map<String, List<String>> parsedIngredients = {};
                        String currentCategory = "Ingredientes"; // Default
                        final lines = _ingredients.text.split('\n');

                        for (String line in lines) {
                          final trimmedLine = line.trim();
                          if (trimmedLine.isEmpty) continue;

                          if (trimmedLine.endsWith(':')) {
                            currentCategory = trimmedLine
                                .substring(0, trimmedLine.length - 1)
                                .trim();
                            if (currentCategory.isEmpty) {
                              currentCategory = "Outros";
                            }
                            parsedIngredients.putIfAbsent(
                                currentCategory, () => []);
                          } else if (parsedIngredients
                              .containsKey(currentCategory)) {
                            parsedIngredients[currentCategory]!
                                .add(trimmedLine);
                          } else {
                            parsedIngredients
                                .putIfAbsent(currentCategory, () => [])
                                .add(trimmedLine);
                          }
                        }
                        parsedIngredients.removeWhere(
                                (key, value) =>
                            value.isEmpty && key != "Ingredientes");
                        if (!parsedIngredients.containsKey("Ingredientes") ||
                            parsedIngredients["Ingredientes"]!.isEmpty) {
                          if (parsedIngredients.values
                              .every((list) => list.isEmpty)) {
                            parsedIngredients["Ingredientes"] = _ingredients.text
                                .split('\n')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList();
                          }
                        }
                        if (parsedIngredients.isEmpty &&
                            _ingredients.text.trim().isNotEmpty) {
                          parsedIngredients["Ingredientes"] = _ingredients.text
                              .split('\n')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();
                        }

                        final profile = userProfile.value;
                        final ownerId = (profile?['id'] as String?) ??
                            ''; // ajuste se preferir pegar do Supabase auth

                        final recipe = Recipe(
                          name: _name.text,
                          description: _description.text,
                          owner: ownerId,
                          ingredients: parsedIngredients,
                          steps: _steps.text
                              .split('\n')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          category: _selectedCategory!,
                          timeMinutes: int.parse(_timeMinutes.text),
                          servings: int.parse(_servings.text),
                          imagePath: null,
                        );
                        await viewModel.create(recipe, _imageFile);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Receita criada com sucesso!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Salvar Receita'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
