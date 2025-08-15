import 'package:flutter/material.dart';

class RecipePage extends StatefulWidget {
  final String title;
  final String imagePath;
  final String time;
  // final String rating; // Rating removed
  final String servings;
  final Map<String, String> ingredients;
  final List<String> preparationSteps;

  const RecipePage({
    super.key,
    required this.title,
    required this.imagePath,
    required this.time,
    // required this.rating, // Rating removed
    required this.servings,
    required this.ingredients,
    required this.preparationSteps,
  });

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  late String _currentTitle;
  late String _currentImagePath;
  late String _currentTime;
  // late String _currentRating; // Rating removed
  late String _currentServings;
  late Map<String, String> _currentIngredients;
  late List<String> _currentPreparationSteps;
  bool _isFavorited = false;

  bool _isEditMode = false; // Should be initialized to false
  String? _editingFieldKey; // Tracks which field is currently being edited
  final TextEditingController _editingController = TextEditingController();

  // For "Add Ingredient" dialog
  final TextEditingController _newIngredientNameController = TextEditingController();
  final TextEditingController _newIngredientDescriptionController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _currentImagePath = widget.imagePath;
    _currentTime = widget.time;
    // _currentRating = widget.rating; // Rating removed
    _currentServings = widget.servings;
    _currentIngredients = Map.from(widget.ingredients); // Create a mutable copy
    _currentPreparationSteps = List.from(widget.preparationSteps); // Create a mutable copy
  }

  @override
  void dispose() {
    _editingController.dispose();
    _newIngredientNameController.dispose();
    _newIngredientDescriptionController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditMode) { // Was true, now turning false (exiting edit mode)
        if (_editingFieldKey != null) {
          _submitEdit(_editingFieldKey!, _editingController.text);
        }
        // SnackBar is shown when entering edit mode
      } else { // Was false, now turning true (entering edit mode)
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Long-press on a text field to edit it. Use buttons to add/remove items.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      _isEditMode = !_isEditMode;
    });
  }

  void _startEditing(String fieldKey, String currentValue) {
    if (!_isEditMode) return; // Should not happen if UI is correct, but as a safeguard
    setState(() {
      _editingFieldKey = fieldKey;
      _editingController.text = currentValue;
    });
  }

  void _submitEdit(String fieldKey, String newValue) {
    setState(() {
      if (fieldKey == 'title') {
        _currentTitle = newValue;
      } else if (fieldKey == 'time') {
        _currentTime = newValue;
      } else if (fieldKey == 'servings') {
        _currentServings = newValue;
      } else if (fieldKey.startsWith('ingredient_')) {
        final ingredientKey = fieldKey.substring('ingredient_'.length);
        if (_currentIngredients.containsKey(ingredientKey)) {
          _currentIngredients[ingredientKey] = newValue;
        }
      } else if (fieldKey.startsWith('step_')) {
        final stepIndex = int.parse(fieldKey.substring('step_'.length));
        if (stepIndex >= 0 && stepIndex < _currentPreparationSteps.length) {
          _currentPreparationSteps[stepIndex] = newValue;
        }
      }
      _editingFieldKey = null;
      _editingController.clear();
    });
  }

  Widget _buildEditableTextWidget({
    required String currentValue,
    required String fieldKey,
    required TextStyle style,
    TextAlign textAlign = TextAlign.start,
  }) {
    if (_isEditMode && _editingFieldKey == fieldKey) {
      return TextField(
        controller: _editingController,
        autofocus: true,
        style: style,
        textAlign: textAlign,
        onSubmitted: (newValue) => _submitEdit(fieldKey, newValue),
        onTapOutside: (_) {
          if (_editingFieldKey == fieldKey) { // Check if still editing this field
             _submitEdit(fieldKey, _editingController.text);
          }
        },
        decoration: const InputDecoration(
          isDense: true,
        ),
      );
    } else {
      return GestureDetector(
        onLongPress: _isEditMode ? () => _startEditing(fieldKey, currentValue) : null,
        child: Text(
          currentValue,
          style: style.copyWith(
            decoration: _isEditMode ? TextDecoration.underline : TextDecoration.none,
            decorationColor: _isEditMode ? Colors.grey : null,
            decorationStyle: _isEditMode ? TextDecorationStyle.dashed : null,
          ),
          textAlign: textAlign,
        ),
      );
    }
  }

  void _addIngredient(String name, String description) {
    setState(() {
      _currentIngredients[name] = description;
    });
  }

  void _removeIngredient(String name) {
    setState(() {
      _currentIngredients.remove(name);
    });
  }

  void _addStep() {
    setState(() {
      _currentPreparationSteps.add("New step. Long-press to edit.");
    });
  }

  void _removeStep(int index) {
    setState(() {
      _currentPreparationSteps.removeAt(index);
    });
  }

  Future<void> _showAddIngredientDialog() async {
    _newIngredientNameController.clear();
    _newIngredientDescriptionController.clear();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Ingredient'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _newIngredientNameController,
                  decoration: const InputDecoration(hintText: "Ingredient Name/Category"),
                ),
                TextField(
                  controller: _newIngredientDescriptionController,
                  decoration: const InputDecoration(hintText: "Description (e.g., 100g)"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (_newIngredientNameController.text.isNotEmpty &&
                    _newIngredientDescriptionController.text.isNotEmpty) {
                  _addIngredient(_newIngredientNameController.text, _newIngredientDescriptionController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isEditMode) { // If in edit mode, confirm exit or offer to save
                 _toggleEditMode(); // For now, just exit edit mode
            }
            Navigator.of(context).pop();
          },
        ),
        title: _isEditMode && _editingFieldKey == 'title' // Show TextField if editing title
               ? SizedBox(
                   width: double.infinity,
                   child: _buildEditableTextWidget(
                     currentValue: _currentTitle,
                     fieldKey: 'title',
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white) ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                     textAlign: TextAlign.center,
                   ),
                 )
                // Otherwise, show Text, potentially with underline if in edit mode
               : GestureDetector(
                  onLongPress: _isEditMode ? () => _startEditing('title', _currentTitle) : null,
                  child: Text(
                     _currentTitle,
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       color: Colors.white,
                       decoration: _isEditMode && _editingFieldKey != 'title' ? TextDecoration.underline : TextDecoration.none,
                       decorationColor: _isEditMode && _editingFieldKey != 'title' ? Colors.grey[300] : null,
                       decorationStyle: _isEditMode && _editingFieldKey != 'title' ? TextDecorationStyle.dashed : null,
                     ) ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                     textAlign: TextAlign.center,
                   ),
                 ),
        centerTitle: true,
         actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit, color: Colors.white), // Changed color back to white
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                _currentImagePath,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text('Image not found.'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0), 
                    child: _buildEditableTextWidget(
                      currentValue: _currentTitle,
                      fieldKey: 'title',
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Row( 
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorited ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFavorited = !_isFavorited;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                const Icon(Icons.timer_outlined, size: 20.0, color: Colors.grey),
                const SizedBox(width: 4.0),
                Expanded(
                  child: _buildEditableTextWidget(
                    currentValue: _currentTime,
                    fieldKey: 'time',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16.0),
                const Icon(Icons.person_outline, size: 20.0, color: Colors.grey),
                const SizedBox(width: 4.0),
                Expanded(
                  child: _buildEditableTextWidget(
                    currentValue: _currentServings,
                    fieldKey: 'servings',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 16.0),

            const Text(
              'Ingredientes',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            ..._currentIngredients.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text( 
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEditableTextWidget(
                            currentValue: entry.value,
                            fieldKey: 'ingredient_${entry.key}',
                            style: const TextStyle(),
                          ),
                        ),
                        if (_isEditMode) // Corrected from _isMode
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 20),
                            onPressed: () => _removeIngredient(entry.key),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }), // Removed .toList()
            if (_isEditMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Add Ingredient'),
                  onPressed: _showAddIngredientDialog,
                ),
              ),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 16.0),

            const Text(
              'Modo de preparo',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            ..._currentPreparationSteps.asMap().entries.map((entry) {
              int idx = entry.key;
              String stepText = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${idx + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _buildEditableTextWidget(
                        currentValue: stepText,
                        fieldKey: 'step_$idx',
                        style: const TextStyle(),
                      ),
                    ),
                    if (_isEditMode)
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 20),
                        onPressed: () => _removeStep(idx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            }), // Removed .toList()
            if (_isEditMode)
             Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Add Step'),
                onPressed: _addStep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

