import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recipe.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../domain/repositories/recipe_repository.dart';
import '../../profile/viewmodel/my_recipes_viewmodel.dart';
import 'home_viewmodel.dart';

class CreateRecipeState {
  final bool saving;
  final String? error;
  const CreateRecipeState({this.saving = false, this.error});

  CreateRecipeState copyWith({bool? saving, String? error}) =>
      CreateRecipeState(
        saving: saving ?? this.saving,
        error: error == '' ? null : (error ?? this.error),
      );
}

class CreateRecipeViewModel extends StateNotifier<CreateRecipeState> {
  final RecipeRepository repo;
  final StorageRepository storageRepo;
  final Ref ref;

  CreateRecipeViewModel(this.repo, this.storageRepo, this.ref) : super(const CreateRecipeState());

  Future<int?> create(Recipe recipe, XFile? imageFile) async {
    state = state.copyWith(saving: true, error: '');
    try {
      String? imageUrl;

      if (imageFile != null && recipe.owner != null) {
        imageUrl = await storageRepo.uploadRecipeImage(
          file: File(imageFile.path),
          userId: recipe.owner!,
        );
      }

      final recipeToSave = recipe.copyWith(imagePath: imageUrl);

      final id = await repo.create(recipeToSave);

      ref.invalidate(homeVmProvider);
      ref.invalidate(myRecipesViewModelProvider);
      state = state.copyWith(saving: false);
      return id;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return null;
    }
  }
}

final createRecipeVmProvider =
StateNotifierProvider<CreateRecipeViewModel, CreateRecipeState>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  final storageRepo = ref.watch(storageRepositoryProvider);
  return CreateRecipeViewModel(repo, storageRepo, ref);
});
