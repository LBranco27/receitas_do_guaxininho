import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_viewmodel.dart';

final registerViewModelProvider =
AsyncNotifierProvider<RegisterViewModel, void>(RegisterViewModel.new);

class RegisterViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref
            .read(authRepositoryProvider)
            .signUpWithEmailAndPassword(email, password, name);
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('user already registered')) {
          throw 'Este email já está cadastrado. Tente fazer o login.';
        }
        if (e.message.toLowerCase().contains('weak password')) {
          throw 'Sua senha é muito fraca. Tente uma mais forte.';
        }
        throw 'Ocorreu um erro ao criar a conta. Tente novamente.';
      }
    });
  }
}

