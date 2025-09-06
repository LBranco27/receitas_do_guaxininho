import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receitas_do_guaxininho/features/auth/viewmodel/profile_providers.dart';
import 'package:receitas_do_guaxininho/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileViewModelProvider =
AsyncNotifierProvider<ProfileViewModel, bool>(ProfileViewModel.new);

class ProfileViewModel extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<bool> uploadAvatar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final picker = ImagePicker();
      final imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
      );

      if (imageFile == null) {
        return false;
      }

      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw 'Usuário não autenticado.';
      }

      final file = File(imageFile.path);
      final fileExtension = imageFile.path.split('.').last;
      final filePath = '${user.id}/avatar.$fileExtension';

      await supabase.storage.from('avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final imageUrl =
      supabase.storage.from('avatars').getPublicUrl(filePath);

      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl}).eq('id', user.id);

      ref.invalidate(userProfileProvider);

      return true;
    });

    return state.value ?? false;
  }
}
