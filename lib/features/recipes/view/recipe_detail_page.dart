import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Added import
import '../viewmodel/recipe_detail_viewmodel.dart';
import '../../../domain/entities/recipe.dart'; // Ensure Recipe entity is imported if needed for type

class RecipeDetailPage extends ConsumerWidget {
  final int id;
  const RecipeDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeDetailVmProvider(id));

    if (state.loading) {
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
      id: r.id!, // Pass id for ViewModel provider
      title: r.name,
      imagePath: r.imagePath ?? 'assets/images/placeholder.png',
      time: '${r.timeMinutes} min',
      servings: '${r.servings} pessoas',
      ingredients: r.ingredients,
      preparationSteps: r.steps,
      isFavorite: r.isFavorite, // Pass initial favorite state
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
  });

  @override
  ConsumerState<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends ConsumerState<RecipePage> {
  bool _isFavorited = false;
  bool _isEditMode = false;
  late TextEditingController _titleController;
  late TextEditingController _timeController;
  late TextEditingController _servingsController;
  late TextEditingController _ingredientsController;
  late TextEditingController _stepsController;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorite;
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
    setState(() {
      _isFavorited = !_isFavorited;
    });
    // Update through ViewModel
    final recipeNotifier = ref.read(recipeDetailVmProvider(widget.id).notifier);
    recipeNotifier.toggleFavorite();
  }

  void _toggleEditMode() {
    final recipeNotifier = ref.read(recipeDetailVmProvider(widget.id).notifier);
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) { // Just exited edit mode (saved)
        // Create an updated Recipe object
        // This requires parsing ingredients and steps from controllers
        // And converting time/servings back to numeric if necessary
        Map<String, List<String>> parsedIngredients = {};
        final lines = _ingredientsController.text.split('\n');
        String currentCategory = '';
        for (var line in lines) {
          if (line.endsWith(':')) {
            currentCategory = line.substring(0, line.length -1);
            parsedIngredients[currentCategory] = [];
          } else if (currentCategory.isNotEmpty && line.trim().isNotEmpty) {
            parsedIngredients[currentCategory]?.add(line.trim());
          }
        }

        List<String> parsedSteps = _stepsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
        
        // Update ViewModel state immediately for UI, then trigger save
        recipeNotifier.updateTitle(_titleController.text);
        recipeNotifier.updateTimeMinutes(_timeController.text); // ViewModel should parse
        recipeNotifier.updateServings(_servingsController.text);   // ViewModel should parse
        recipeNotifier.updateIngredientsText(_ingredientsController.text); // ViewModel can handle parsing
        recipeNotifier.updateStepsText(_stepsController.text); // ViewModel can handle parsing

        // Tell ViewModel to finalize and save the update
        recipeNotifier.saveRecipe();

      } else { // Just entered edit mode
        // Reset fields to original widget values or current ViewModel state
        // This ensures if a save failed or data was reloaded, edit fields are fresh
        final currentState = ref.read(recipeDetailVmProvider(widget.id));
        _titleController.text = currentState.recipe?.name ?? widget.title;
        _timeController.text = (currentState.recipe?.timeMinutes ?? widget.time.replaceAll(RegExp(r'[^0-9]'), '')).toString();
        _servingsController.text = (currentState.recipe?.servings ?? widget.servings.replaceAll(RegExp(r'[^0-9]'), '')).toString();
        
        String ingredientsText = '';
        (currentState.recipe?.ingredients ?? widget.ingredients).forEach((category, items) {
          ingredientsText += '$category:\n';
          items.forEach((item) => ingredientsText += '  $item\n');
          ingredientsText += '\n';
        });
        _ingredientsController.text = ingredientsText.trim();
        _stepsController.text = (currentState.recipe?.steps ?? widget.preparationSteps).join('\n');
        
        // Also update the local _isFavorited state from the ViewModel
        _isFavorited = currentState.recipe?.isFavorite ?? widget.isFavorite;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRecipeState = ref.watch(recipeDetailVmProvider(widget.id));
    final displayTitle = _isEditMode ? _titleController.text : (currentRecipeState.recipe?.name ?? widget.title);

    // Update local _isFavorited if ViewModel changed it (e.g. after initial load)
    // This is a bit of a workaround for ConsumerStatefulWidget not directly re-running initState on provider change
    if (currentRecipeState.recipe != null && _isFavorited != currentRecipeState.recipe!.isFavorite && !_isEditMode) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted){
          setState(() {
            _isFavorited = currentRecipeState.recipe!.isFavorite;
          });
        }
      });
    }


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
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: widget.imagePath!.startsWith('assets/')
                    ? Image.asset(
                        widget.imagePath!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(widget.imagePath!),
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            if (widget.imagePath == null || widget.imagePath!.isEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_camera, color: Colors.grey[600], size: 50),
              ),
            const SizedBox(height: 16),
            if (!_isEditMode) // Display title as Text when not editing
              Text(
                displayTitle,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            // Title TextField is in AppBar when editing

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
                    icon: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border),
                    onPressed: _toggleFavorite,
                    color: _isFavorited ? theme.colorScheme.primary : null,
                  ),
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
