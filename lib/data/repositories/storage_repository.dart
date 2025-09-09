import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repositório para interagir com o Supabase Storage
class StorageRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Faz o upload da imagem da receita e retorna a URL pública
  Future<String> uploadRecipeImage({
    required File file,
    required String userId,
  }) async {
    try {
      // Cria um caminho único para o arquivo para evitar sobreposições
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';

      // Faz o upload para o bucket 'recipes'
      await _client.storage.from('recipes').upload(filePath, file);

      // Retorna a URL pública da imagem que acabamos de enviar
      return _client.storage.from('recipes').getPublicUrl(filePath);
    } catch (e) {
      // Em caso de erro, você pode tratar de forma mais específica
      print('Erro no upload da imagem: $e');
      throw Exception('Falha ao enviar imagem da receita.');
    }
  }
}

// Provider para o nosso novo repositório
final storageRepositoryProvider = Provider((ref) => StorageRepository());