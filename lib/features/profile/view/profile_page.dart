import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receitas_do_guaxininho/features/auth/viewmodel/profile_providers.dart';
import '../viewmodel/profile_viewmodel.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final profileViewModel = ref.watch(profileViewModelProvider);

    ref.listen<AsyncValue<bool>>(profileViewModelProvider, (_, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }

      if (!state.isLoading && state.hasValue && state.value == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto de perfil atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: userProfile.when(
        data: (profile) {
          final name = profile?['name'] as String?;
          final avatarUrl = profile?['avatar_url'] as String?;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person,
                        size: 80, color: Colors.grey.shade600)
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name ?? 'Usuário',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 40),
                  profileViewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Alterar Foto'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      ref
                          .read(profileViewModelProvider.notifier)
                          .uploadAvatar();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) =>
            Center(child: Text('Erro ao carregar perfil: $e')),
      ),
    );
  }
}
