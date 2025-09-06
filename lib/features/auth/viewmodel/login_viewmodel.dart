import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/auth_repository.dart';

final loginViewModelProvider =
AsyncNotifierProvider<LoginViewModel, void>(LoginViewModel.new);

class LoginViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final authRepository = ref.read(authRepositoryProvider);
        await authRepository.signInWithEmailAndPassword(email, password);
      } on AuthException catch (e) {
        if (e.statusCode == '400') {
          throw 'Email ou senha inválidos. Tente novamente.';
        }
        throw 'Ocorreu um erro ao fazer login. Tente novamente.';
      }
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError();
});
