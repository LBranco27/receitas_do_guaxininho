import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:postgrest/src/types.dart';

class Recipe {
  final int? id;
  final String name;
  final String description;
  final Map<String, List<String>> ingredients;
  final List<String> steps;
  final String category;
  final int timeMinutes;
  final int servings;
  final bool isFavorite;
  final String? imagePath; // Tornando imagePath opcional

  Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.category,
    required this.timeMinutes,
    required this.servings,
    this.isFavorite = false,
    this.imagePath,
  });

  Recipe copyWith({
    int? id,
    String? name,
    String? description,
    Map<String, List<String>>? ingredients,
    List<String>? steps,
    String? category,
    int? timeMinutes,
    int? servings,
    bool? isFavorite,
    String? imagePath,
    bool? clearImagePath, // Para explicitamente setar imagePath como null
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
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: clearImagePath == true ? null : imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': jsonEncode(ingredients), // Store as JSON string
      'steps': jsonEncode(steps), // Store as JSON string
      'category': category,
      'time_minutes': timeMinutes,
      'servings': servings,
      'is_favorite': isFavorite ? 1 : 0,
      'image_path': imagePath,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    Map<String, List<String>> parsedIngredients = {};
    try {
      final ingredientsData = jsonDecode(map['ingredients'] as String);

      if (ingredientsData is Map) {
        // New format: Map<String, List<String>> or Old format: Map<String, String>
        ingredientsData.forEach((key, value) {
          if (value is List) {
            // Correct new format
            parsedIngredients[key.toString()] =
                List<String>.from(value.map((e) => e.toString()));
          } else if (value is String) {
            // Old Map<String, String> format, convert to Map<String, List<String>>
            parsedIngredients[key.toString()] = [value];
          } else {
             // Unexpected value type
            if (kDebugMode) {
              print('[Recipe.fromMap Warning] Unexpected type for ingredient value under key "$key": ${value.runtimeType}');
            }
            parsedIngredients[key.toString()] = [value.toString()]; // Best effort
          }
        });
      } else if (ingredientsData is List) {
        // Oldest List<String> format, group under a default category
        parsedIngredients['Ingredientes'] =
            List<String>.from(ingredientsData.map((e) => e.toString()));
      } else {
        if (kDebugMode) {
          print('[Recipe.fromMap Error] Unrecognized format for ingredients for recipe ID ${map['id']}: ${ingredientsData.runtimeType}');
        }
         // Fallback to empty or a special error key if necessary
        parsedIngredients['Erro ao Carregar Ingredientes'] = [(map['ingredients'] as String? ?? 'Dados inválidos')];
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[Recipe.fromMap Error] Failed to parse ingredients for recipe ID ${map['id']}: $e');
        print('[Recipe.fromMap StackTrace] $s');
      }
      // Fallback to empty or include raw data under an error key
      parsedIngredients['Erro ao Decodificar Ingredientes'] = [(map['ingredients'] as String? ?? 'Dados brutos indisponíveis')];
    }

    List<String> parsedSteps = [];
    try {
      final stepsData = jsonDecode(map['steps'] as String);
      if (stepsData is List) {
        parsedSteps = List<String>.from(stepsData.map((e) => e.toString()));
      } else {
         if (kDebugMode) {
           print('[Recipe.fromMap Warning] Steps data is not a list for recipe ID ${map['id']}. Found: ${stepsData.runtimeType}');
         }
         parsedSteps = [(map['steps'] as String? ?? '')]; // Best effort
      }
    } catch (e) {
       if (kDebugMode) {
         print('[Recipe.fromMap Error] Failed to parse steps for recipe ID ${map['id']}: $e');
       }
       parsedSteps = [(map['steps'] as String? ?? 'Erro ao decodificar passos')];
    }


    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      ingredients: parsedIngredients,
      steps: parsedSteps,
      category: map['category'] as String,
      timeMinutes: map['time_minutes'] as int,
      servings: map['servings'] as int,
      isFavorite: (map['is_favorite'] as int?) == 1,
      imagePath: map['image_path'] as String?,
    );
  }

  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, description: $description, ingredients: $ingredients, steps: $steps, category: $category, timeMinutes: $timeMinutes, servings: $servings, isFavorite: $isFavorite, imagePath: $imagePath)';
  }

}
