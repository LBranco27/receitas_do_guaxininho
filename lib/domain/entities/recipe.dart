import 'dart:convert';
import 'package:flutter/foundation.dart';

class Recipe {
  final int? id;
  final String name;
  final String description;
  final String? owner;
  final Map<String, List<String>> ingredients;
  final List<String> steps;
  final String category;
  final int timeMinutes;
  final int servings;
  final bool isFavorite;

  /// Pode ser null ou URL/path. String vazia é normalizada para null.
  final String? imagePath;

  Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.owner,
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
    String? owner,
    Map<String, List<String>>? ingredients,
    List<String>? steps,
    String? category,
    int? timeMinutes,
    int? servings,
    bool? isFavorite,
    String? imagePath,
    bool? clearImagePath, // se true, força imagePath = null
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      owner: owner ?? this.owner,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      category: category ?? this.category,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      servings: servings ?? this.servings,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: clearImagePath == true ? null : (imagePath ?? this.imagePath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'owner': owner,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'timeMinutes': timeMinutes,
      'servings': servings,
      'imagePath': imagePath,
    };
  }

  // --------------------- Parsers resilientes ---------------------

  static Map<String, List<String>> _parseIngredients(dynamic raw) {
    dynamic v = raw;

    // Se vier como String JSON, tenta decodificar
    if (v is String && v.trim().isNotEmpty) {
      try {
        v = jsonDecode(v);
      } catch (_) {
        // se não decodificar, segue com a string crua
      }
    }

    // Caso 1: já é um mapa {secao: [itens]}
    if (v is Map) {
      final out = <String, List<String>>{};
      v.forEach((key, val) {
        final k = key?.toString() ?? 'Ingredientes';
        if (val is List) {
          out[k] = val.map((e) => e.toString()).toList();
        } else if (val is String) {
          out[k] = [val];
        } else if (val == null) {
          out[k] = const <String>[];
        } else {
          if (kDebugMode) {
            print(
              '[Recipe.fromMap] Valor inesperado em ingredients["$k"]: ${val.runtimeType}',
            );
          }
          out[k] = [val.toString()];
        }
      });
      return out;
    }

    // Caso 2: é um array simples -> coloca tudo numa seção padrão
    if (v is List) {
      return {'Ingredientes': v.map((e) => e.toString()).toList()};
    }

    // Caso 3: qualquer outra coisa -> retorna vazio (ou coloca sob uma chave de erro)
    if (v != null && (v is String && v.trim().isNotEmpty)) {
      return {
        'Ingredientes': [v.toString()],
      };
    }

    return <String, List<String>>{};
  }

  static List<String> _parseSteps(dynamic raw) {
    dynamic v = raw;

    if (v is String && v.trim().isNotEmpty) {
      // pode ser um JSON string ou um texto simples
      try {
        final decoded = jsonDecode(v);
        v = decoded;
      } catch (_) {
        // não é JSON, trata como texto único
        return [v];
      }
    }

    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return [v];

    return const <String>[];
  }

  static String? _normalizeImagePath(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int _parseInt(dynamic raw, {int defaultValue = 0}) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final n = int.tryParse(raw);
      if (n != null) return n;
    }
    return defaultValue;
  }

  static bool _parseIsFavorite(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is int) return raw == 1;
    if (raw is String) {
      final s = raw.toLowerCase().trim();
      return s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y';
    }
    return false;
  }

  // --------------------- Factory principal ---------------------

  factory Recipe.fromMap(Map<String, dynamic> map) {
    if (kDebugMode) {
      // print(map);
    }

    final ingredients = _parseIngredients(map['ingredients']);
    final steps = _parseSteps(map['steps']);

    // Aceita variações de nomes: timeMinutes vs time_minutes; imagePath vs image_path
    final timeMinutes = _parseInt(
      map['timeMinutes'] ?? map['time_minutes'] ?? 0,
    );
    final servings = _parseInt(map['servings'] ?? 0);

    return Recipe(
      id: map['id'] is int ? map['id'] as int : _parseInt(map['id']),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      owner: map['owner']?.toString(),
      ingredients: ingredients,
      steps: steps,
      category: map['category']?.toString() ?? '',
      timeMinutes: timeMinutes,
      servings: servings,
      isFavorite: _parseIsFavorite(map['isFavorite'] ?? map['is_favorite']),
      imagePath: _normalizeImagePath(map['imagePath'] ?? map['image_path']),
    );
  }

  @override
  String toString() {
    return 'Recipe('
        'id: $id, '
        'name: $name, '
        'description: $description, '
        'owner: $owner, '
        'ingredients: $ingredients, '
        'steps: $steps, '
        'category: $category, '
        'timeMinutes: $timeMinutes, '
        'servings: $servings, '
        'isFavorite: $isFavorite, '
        'imagePath: $imagePath'
        ')';
  }
}
