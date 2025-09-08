import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/main.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return null;
  }

  final supabase = ref.watch(supabaseClientProvider);

  try {
    final data = await supabase
        .from('profiles')
        .select('id, name, avatar_url')
        .eq('id', user.id)
        .single();

    print("Dados do user: $data ");
    return data;
  } catch (e) {
    print('Erro ao buscar perfil: $e');
    return null;
  }
});

final anyUserProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final data = await supabase
        .from('profiles')
        .select('id, name, avatar_url')
        .eq('id', userId)
        .single();
    return data;
  } catch (e) {
    print('Erro ao buscar perfil do usuário $userId: $e');
    return null;
  }
});