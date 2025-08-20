import 'dart:convert';

class Recipe {
  final int? id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String category;
  final int timeMinutes;
  final int servings;
  final String? imagePath;
  final bool isFavorite;

  const Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.category,
    required this.timeMinutes,
    required this.servings,
    this.imagePath,
    this.isFavorite = false,
  });

  Recipe copyWith({
    int? id,
    String? name,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
    String? category,
    int? timeMinutes,
    int? servings,
    String? imagePath,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      category: category ?? this.category,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      servings: servings ?? this.servings,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'ingredients': jsonEncode(ingredients),
    'steps': jsonEncode(steps),
    'category': category,
    'time_minutes': timeMinutes,
    'servings': servings,
    'image_path': imagePath,
    'is_favorite': isFavorite ? 1 : 0,
  };

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
    id: map['id'] as int?,
    name: map['name'] as String,
    description: map['description'] as String,
    ingredients: List<String>.from(jsonDecode(map['ingredients'] as String)),
    steps: List<String>.from(jsonDecode(map['steps'] as String)),
    category: map['category'] as String,
    timeMinutes: map['time_minutes'] as int,
    servings: map['servings'] as int,
    imagePath: map['image_path'] as String?,
    isFavorite: (map['is_favorite'] as int) == 1,
  );
}
