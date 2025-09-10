import 'package:supabase_flutter/supabase_flutter.dart';

const String kRecipeImagesBucket = 'recipes';

/// - http/https -> retorna como está
/// - caminho local (file://, /data/...) -> retorna null (não dá pra usar no web)
/// - chave de storage (ex.: "userId/arquivo.jpg") -> gera public URL
String? resolveRecipeImageUrl(String? imagePath) {
  if (imagePath == null) return null;
  final p = imagePath.trim();
  if (p.isEmpty) return null;

  final lower = p.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return p;
  }

  // Caminhos locais de dispositivo (não funcionam no web)
  if (lower.startsWith('file://') || lower.startsWith('/data/')) {
    return null;
  }

  return Supabase.instance.client.storage
      .from(kRecipeImagesBucket)
      .getPublicUrl(p);
}
