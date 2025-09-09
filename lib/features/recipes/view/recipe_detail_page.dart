import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Added import
import 'package:receitas_do_guaxininho/features/auth/viewmodel/profile_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodel/recipe_detail_viewmodel.dart';
import '../../../domain/entities/recipe.dart'; // Ensure Recipe entity is imported if needed for type

class RecipeDetailPage extends ConsumerWidget {
  final int id;
  const RecipeDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeDetailVmProvider(id));

    if (state.loading && state.recipe == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null) {
      return Scaffold(body: Center(child: Text('Erro: ${state.error}')));
    }
    final Recipe? r = state.recipe; // Explicitly type r
    if (r == null) {
      return const Scaffold(body: Center(child: Text('Receita não encontrada')));
    }

    // Pass the initial favorite state from the loaded recipe
    return RecipePage(
      key: ValueKey(r.id),
      id: r.id!, // Pass id for ViewModel provider
      title: r.name,
      imagePath: r.imagePath ?? 'assets/images/placeholder.png',
      time: '${r.timeMinutes} min',
      servings: '${r.servings} pessoas',
      ingredients: r.ingredients,
      preparationSteps: r.steps,
      isFavorite: r.isFavorite, // Pass initial favorite state
      ownerId: r.owner
    );
  }
}

class RecipePage extends ConsumerStatefulWidget {
  final int id; // Needed for ViewModel
  final String title;
  final String? imagePath;
  final String time;
  final String servings;
  final Map<String, List<String>> ingredients;
  final List<String> preparationSteps;
  final bool isFavorite;
  final String? ownerId;

  const RecipePage({
    super.key,
    required this.id,
    required this.title,
    this.imagePath,
    required this.time,
    required this.servings,
    required this.ingredients,
    required this.preparationSteps,
    required this.isFavorite,
    required this.ownerId,
  });


  @override
  ConsumerState<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends ConsumerState<RecipePage> {
  XFile? _newImageFile;
  bool _isEditMode = false;
  late TextEditingController _titleController;
  late TextEditingController _timeController;
  late TextEditingController _servingsController;
  late TextEditingController _ingredientsController;
  late TextEditingController _stepsController;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newImageFile = image;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    // Extract numeric part for time and servings for editing
    _timeController = TextEditingController(text: widget.time.replaceAll(RegExp(r'[^0-9]'), ''));
    _servingsController = TextEditingController(text: widget.servings.replaceAll(RegExp(r'[^0-9]'), ''));

    String ingredientsText = '';
    widget.ingredients.forEach((category, items) {
      ingredientsText += '$category:\n';
      for (var item in items) {
        ingredientsText += '  $item\n';
      }
      ingredientsText += '\n';
    });
    _ingredientsController = TextEditingController(text: ingredientsText.trim());
    _stepsController = TextEditingController(text: widget.preparationSteps.join('\n'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _servingsController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    ref.read(recipeDetailVmProvider(widget.id).notifier).toggleFavorite();
  }

  void _toggleEditMode() {
    final recipeNotifier = ref.read(recipeDetailVmProvider(widget.id).notifier);

    if (_isEditMode) {
      final currentRecipe = ref.read(recipeDetailVmProvider(widget.id)).recipe;
      if (currentRecipe == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Não foi possível encontrar a receita para salvar.'))
        );
        return;
      }

      Map<String, List<String>> parsedIngredients = {};
      final lines = _ingredientsController.text.split('\n');
      String currentCategory = '';
      for (var line in lines) {
        if (line.trim().endsWith(':')) {
          currentCategory = line.trim().substring(0, line.trim().length - 1);
          parsedIngredients[currentCategory] = [];
        } else if (currentCategory.isNotEmpty && line.trim().isNotEmpty) {
          parsedIngredients[currentCategory]?.add(line.trim());
        }
      }
      List<String> parsedSteps = _stepsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();

      final updatedRecipe = currentRecipe.copyWith(
        name: _titleController.text,
        timeMinutes: int.tryParse(_timeController.text) ?? currentRecipe.timeMinutes,
        servings: int.tryParse(_servingsController.text) ?? currentRecipe.servings,
        ingredients: parsedIngredients,
        steps: parsedSteps,
      );

      recipeNotifier.saveRecipe(updatedRecipe, _newImageFile);

      setState(() {
        _isEditMode = false;
        _newImageFile = null;
      });

    } else {
      final currentState = ref.read(recipeDetailVmProvider(widget.id));
      _titleController.text = currentState.recipe?.name ?? widget.title;
      _timeController.text = (currentState.recipe?.timeMinutes ?? '').toString();
      _servingsController.text = (currentState.recipe?.servings ?? '').toString();

      String ingredientsText = '';
      (currentState.recipe?.ingredients ?? widget.ingredients).forEach((category, items) {
        ingredientsText += '$category:\n';
        for (var item in items) {
          ingredientsText += '  $item\n';
        }
        ingredientsText += '\n';
      });
      _ingredientsController.text = ingredientsText.trim();
      _stepsController.text = (currentState.recipe?.steps ?? widget.preparationSteps).join('\n');

      setState(() {
        _isEditMode = true;
      });
    }
  }
  
  Future<void> _confirmDeleteRecipe() async {
    // Access the notifier for calling ViewModel methods
    final recipeNotifier = ref.read(recipeDetailVmProvider(widget.id).notifier);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir esta receita? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Dismiss dialog, return false
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Dismiss dialog, return true
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await recipeNotifier.deleteCurrentRecipe();

      if (mounted) {
        context.go('/'); // Changed to use context.go
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    final theme = Theme.of(context); // Ensuring theme context
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      label: Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      visualDensity: VisualDensity.compact, // To reduce default padding if it's too much
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    if (widget.ingredients.isEmpty && !_isEditMode) { // Check edit mode
      return const Text('Nenhum ingrediente listado.', style: TextStyle(fontStyle: FontStyle.italic));
    }
    List<Widget> ingredientWidgets = [];
    final ingredientsToShow = _isEditMode ? {} : widget.ingredients; // Simplified for brevity, use controller in edit mode
    
    // In a real scenario, for edit mode, you'd parse _ingredientsController.text or have a live list
    if(!_isEditMode) {
      widget.ingredients.forEach((category, items) {
        ingredientWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              category,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
        items.forEach((item) {
          ingredientWidgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 2.0),
              child: Text(
                '• $item',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        });
      });
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: ingredientWidgets);
  }

  Widget _buildStepsSection() {
    if (widget.preparationSteps.isEmpty && !_isEditMode) { // Check edit mode
      return const Text('Nenhum passo listado.', style: TextStyle(fontStyle: FontStyle.italic));
    }
    // In a real scenario, for edit mode, you'd parse _stepsController.text or have a live list
    if (!_isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.preparationSteps.asMap().entries.map((entry) {
          int idx = entry.key;
          String step = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '${idx + 1}. $step',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }).toList(),
      );
    }
    return Container(); // Placeholder for steps TextField in edit mode
  }

  Widget _buildImageSection(RecipeDetailState currentRecipeState) {
    final currentImage = currentRecipeState.recipe?.imagePath;

    if (_isEditMode) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: _newImageFile != null
                ? Image.file(
              File(_newImageFile!.path),
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : (currentImage != null && currentImage.isNotEmpty
                ? Image.network(
              currentImage,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_camera, color: Colors.grey[600], size: 50),
            )),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton(
              onPressed: _pickImage,
              mini: true,
              child: const Icon(Icons.edit),
            ),
          ),
        ],
      );
    }

    if (currentImage != null && currentImage.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          currentImage,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
            if (kDebugMode) {
              print('Error loading network image: $widget.imagePath, Exception: $exception');
            }
            return Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12), // Match your style
              ),
              child: Icon(Icons.broken_image, color: Colors.grey[600], size: 50),
            );
          },
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.photo_camera, color: Colors.grey[600], size: 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRecipeState = ref.watch(recipeDetailVmProvider(widget.id));
    final displayTitle = _isEditMode ? _titleController.text : (currentRecipeState.recipe?.name ?? widget.title);
    final recipe = currentRecipeState.recipe;
    final ownerId = widget.ownerId; // Use widget.ownerId
    final isFavorited = recipe?.isFavorite ?? widget.isFavorite;
    final _supabaseClient = Supabase.instance.client;
    final currentUserId = _supabaseClient.auth.currentUser?.id;
    final bool isOwner = currentUserId != null && ownerId != null && ownerId == currentUserId;

    // Watch for owner profile data
    final ownerProfileAsyncValue = ownerId != null ? ref.watch(anyUserProfileProvider(ownerId)) : null;

    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
            ? TextField(
                controller: _titleController,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'Nome da Receita',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150)),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  // Optional: Live update to ViewModel if desired, or wait for save
                  // ref.read(recipeDetailVmProvider(widget.id).notifier).updateTitle(value);
                },
              )
            : Text(displayTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildImageSection(currentRecipeState),
            const SizedBox(height: 16),
            if (!_isEditMode) // Display title as Text when not editing
              Text(
                displayTitle,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            // Title TextField is in AppBar when editing
            if (ownerId != null && ownerProfileAsyncValue != null && !_isEditMode) ...[
              const SizedBox(height: 8),
              ownerProfileAsyncValue.when(
                data: (profileData) {
                  if (profileData == null) return const SizedBox.shrink();

                  final username = profileData['name'] as String? ?? 'Usuário';
                  final avatarUrl = profileData['avatar_url'] as String?;

                  return InkWell(
                    onTap: () => context.push('/user/$ownerId'),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Por $username',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (err, stack) => const SizedBox.shrink(), // Caso dê ruim, é melhor n mostrar nada
              ),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: <Widget>[
                  if (!_isEditMode)
                    _buildInfoChip(Icons.timer_outlined, widget.time) // Use widget.time when not editing
                  else
                    SizedBox(
                      width: 100, // Fixed width for TextField
                      child: TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(labelText: 'Tempo (min)', border: InputBorder.none),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  const SizedBox(width: 16.0),
                  if (!_isEditMode)
                    _buildInfoChip(Icons.restaurant_outlined, widget.servings) // Use widget.servings when not editing
                  else
                    SizedBox(
                      width: 100, // Fixed width for TextField
                      child: TextField(
                        controller: _servingsController,
                        decoration: const InputDecoration(labelText: 'Porções', border: InputBorder.none),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border),
                    onPressed: _toggleFavorite,
                    color: isFavorited ? theme.colorScheme.primary : null,
                  ),
                  if (isOwner)
                    IconButton(
                      icon: Icon(_isEditMode ? Icons.check : Icons.edit),
                      onPressed: _toggleEditMode,
                    ),
                ],
              ),
            ),
            _buildSectionTitle('Ingredientes'),
            if (!_isEditMode)
              _buildIngredientsSection()
            else
              TextField(
                controller: _ingredientsController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Ingredientes',
                  hintText: 'Categoria1:\n  Item1\n  Item2\nCategoria2:\n  Item3',
                  border: OutlineInputBorder(),
                ),
              ),
            _buildSectionTitle('Modo de Preparo'),
            if (!_isEditMode)
              _buildStepsSection()
            else
              TextField(
                controller: _stepsController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Modo de Preparo',
                  hintText: 'Passo 1\nPasso 2',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_isEditMode) ...[
              const SizedBox(height: 24), // Spacing before the button
              Center( // Center the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Destructive action color
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: _confirmDeleteRecipe, // This method will be added
                  child: const Text('Excluir Receita', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16), // Spacing after the button
            ],
          ],
        ),
      ),
    );
  }
}
