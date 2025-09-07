import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/main.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;

  if (user == null) {
    return null;
  }

  try {
    final data = await supabase
        .from('profiles')
        .select('name, avatar_url')
        .eq('id', user.id)
        .single();

    print("Dados do user: $data ");
    return data;
  } catch (e) {
    print('Erro ao buscar perfil: $e');
    return null;
  }
});
