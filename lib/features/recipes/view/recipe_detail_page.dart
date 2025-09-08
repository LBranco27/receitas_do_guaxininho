import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receitas_do_guaxininho/features/auth/viewmodel/profile_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodel/recipe_detail_viewmodel.dart';
import '../../../domain/entities/recipe.dart';

import '../../comments/viewmodel/recipe_comments_viewmodel.dart';
import '../../../domain/entities/comment.dart';
import 'package:intl/intl.dart';

// BEGIN: ADDED FOR REVIEWS
import '../../reviews/viewmodel/recipe_reviews_viewmodel.dart';
import '../../../domain/entities/review.dart' as app_review; // Aliased to avoid conflict
// END: ADDED FOR REVIEWS

class RecipeDetailPage extends ConsumerWidget {
  final int id;
  const RecipeDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recipeDetailVmProvider(id));

    if (state.loading && state.recipe == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null) {
      return Scaffold(body: Center(child: Text('Erro: ${state.error}')));
    }
    final Recipe? r = state.recipe;
    if (r == null) {
      return const Scaffold(body: Center(child: Text('Receita não encontrada')));
    }

    return RecipePage(
      key: ValueKey(r.id),
      id: r.id!,
      title: r.name,
      imagePath: r.imagePath ?? 'assets/images/placeholder.png',
      time: '${r.timeMinutes} min',
      servings: '${r.servings} pessoas',
      ingredients: r.ingredients,
      preparationSteps: r.steps,
      isFavorite: r.isFavorite,
      ownerId: r.owner
    );
  }
}

class RecipePage extends ConsumerStatefulWidget {
  final int id;
  final String title;
  final String? imagePath;
  final String time;
  final String servings;
  final Map<String, List<String>> ingredients;
  final List<String> preparationSteps;
  final bool isFavorite;
  final String? ownerId;

  const RecipePage({
    super.key,
    required this.id,
    required this.title,
    this.imagePath,
    required this.time,
    required this.servings,
    required this.ingredients,
    required this.preparationSteps,
    required this.isFavorite,
    required this.ownerId,
  });


  @override
  ConsumerState<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends ConsumerState<RecipePage> {
  bool _isEditMode = false;
  late TextEditingController _titleController;
  late TextEditingController _timeController;
  late TextEditingController _servingsController;
  late TextEditingController _ingredientsController;
  late TextEditingController _stepsController;
  late TextEditingController _commentController;

  // BEGIN: ADDED FOR REVIEWS
  late TextEditingController _reviewTextController;
  double _currentRatingInput = 0; // For review input form
  // END: ADDED FOR REVIEWS

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _timeController = TextEditingController(text: widget.time.replaceAll(RegExp(r'[^0-9]'), ''));
    _servingsController = TextEditingController(text: widget.servings.replaceAll(RegExp(r'[^0-9]'), ''));

    String ingredientsText = '';
    widget.ingredients.forEach((category, items) {
      ingredientsText += '$category:\n';
      for (var item in items) {
        ingredientsText += '  $item\n';
      }
      ingredientsText += '\n';
    });
    _ingredientsController = TextEditingController(text: ingredientsText.trim());
    _stepsController = TextEditingController(text: widget.preparationSteps.join('\n'));
    _commentController = TextEditingController();

    // BEGIN: ADDED FOR REVIEWS
    _reviewTextController = TextEditingController();
    // Initial fetch for current user's review if logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        ref.read(recipeReviewsProvider(widget.id).notifier).fetchCurrentUserReview(currentUserId);
      }
    });
    // END: ADDED FOR REVIEWS
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _servingsController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _commentController.dispose();
    // BEGIN: ADDED FOR REVIEWS
    _reviewTextController.dispose();
    // END: ADDED FOR REVIEWS
    super.dispose();
  }

  void _toggleFavorite() {
    ref.read(recipeDetailVmProvider(widget.id).notifier).toggleFavorite();
  }

  void _toggleEditMode() {
    final recipeNotifier = ref.read(recipeDetailVmProvider(widget.id).notifier);
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) { 
        Map<String, List<String>> parsedIngredients = {};
        final lines = _ingredientsController.text.split('\n');
        String currentCategory = '';
        for (var line in lines) {
          if (line.endsWith(':')) {
            currentCategory = line.substring(0, line.length -1);
            parsedIngredients[currentCategory] = [];
          } else if (currentCategory.isNotEmpty && line.trim().isNotEmpty) {
            parsedIngredients[currentCategory]?.add(line.trim());
          }
        }

        List<String> parsedSteps = _stepsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
        
        recipeNotifier.updateTitle(_titleController.text);
        recipeNotifier.updateTimeMinutes(_timeController.text); 
        recipeNotifier.updateServings(_servingsController.text);   
        recipeNotifier.updateIngredientsText(_ingredientsController.text); 
        recipeNotifier.updateStepsText(_stepsController.text); 

        recipeNotifier.saveRecipe();

      } else { 
        final currentState = ref.read(recipeDetailVmProvider(widget.id));
        _titleController.text = currentState.recipe?.name ?? widget.title;
        _timeController.text = (currentState.recipe?.timeMinutes ?? widget.time.replaceAll(RegExp(r'[^0-9]'), '')).toString();
        _servingsController.text = (currentState.recipe?.servings ?? widget.servings.replaceAll(RegExp(r'[^0-9]'), '')).toString();
        
        String ingredientsText = '';
        (currentState.recipe?.ingredients ?? widget.ingredients).forEach((category, items) {
          ingredientsText += '$category:\n';
          items.forEach((item) => ingredientsText += '  $item\n');
          ingredientsText += '\n';
        });
        _ingredientsController.text = ingredientsText.trim();
        _stepsController.text = (currentState.recipe?.steps ?? widget.preparationSteps).join('\n');
      }
    });
  }
  
  Future<void> _confirmDeleteRecipe() async {
    final recipeNotifier = ref.read(recipeDetailVmProvider(widget.id).notifier);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir esta receita? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); 
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); 
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await recipeNotifier.deleteCurrentRecipe();
      if (mounted) {
        context.go('/'); 
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    final theme = Theme.of(context); 
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      label: Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      visualDensity: VisualDensity.compact, 
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    if (widget.ingredients.isEmpty && !_isEditMode) { 
      return const Text('Nenhum ingrediente listado.', style: TextStyle(fontStyle: FontStyle.italic));
    }
    List<Widget> ingredientWidgets = [];
    
    if(!_isEditMode) {
      widget.ingredients.forEach((category, items) {
        ingredientWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              category,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
        items.forEach((item) {
          ingredientWidgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 2.0),
              child: Text(
                '• $item',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        });
      });
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: ingredientWidgets);
  }

  Widget _buildStepsSection() {
    if (widget.preparationSteps.isEmpty && !_isEditMode) { 
      return const Text('Nenhum passo listado.', style: TextStyle(fontStyle: FontStyle.italic));
    }
    if (!_isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.preparationSteps.asMap().entries.map((entry) {
          int idx = entry.key;
          String step = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '${idx + 1}. $step',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }).toList(),
      );
    }
    return Container(); 
  }

  Widget _buildCommentsSection(String currentUserId) {
    final commentsAsyncValue = ref.watch(recipeCommentsProvider(widget.id.toString()));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Comentários'),
        commentsAsyncValue.when(
          data: (comments) {
            return Column(
              children: [
                if (comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Nenhum comentário ainda. Seja o primeiro!', style: TextStyle(fontStyle: FontStyle.italic)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _CommentItem(comment: comment, currentUserId: currentUserId, recipeId: widget.id.toString());
                    },
                  ),
                const SizedBox(height: 16),
                if (currentUserId.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Adicione um comentário...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: theme.colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _postComment(currentUserId),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: theme.colorScheme.primary),
                        onPressed: () => _postComment(currentUserId),
                        tooltip: 'Postar comentário',
                      ),
                    ],
                  )
                else
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 16.0),
                     child: Text('Você precisa estar logado para comentar.', style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
                   ),
              ],
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          error: (error, stackTrace) {
            if (kDebugMode) {
              print('[CommentsSection Error] $error');
              print('[CommentsSection StackTrace] $stackTrace');
            }
            return Center(child: Text('Erro ao carregar comentários: ${error.toString()}', style: TextStyle(color: theme.colorScheme.error)));
          },
        ),
      ],
    );
  }

  void _postComment(String currentUserId) {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentário não pode estar vazio.')),
      );
      return;
    }
    if (currentUserId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para comentar.')),
      );
      return;
    }

    ref.read(recipeCommentsProvider(widget.id.toString()).notifier).addComment(
      recipeId: widget.id.toString(),
      userId: currentUserId,
      text: _commentController.text.trim(),
    ).then((_) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }).catchError((e) {
      if (kDebugMode) {
        print('Error posting comment from UI: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao postar comentário: ${e.toString()}')),
      );
    });
  }

  // BEGIN: ADDED FOR REVIEWS
  Widget _buildReviewsSection(String currentUserId) {
    final reviewsState = ref.watch(recipeReviewsProvider(widget.id));
    final theme = Theme.of(context);

    // Update form if current user's review is loaded
    ref.listen<RecipeReviewsState>(recipeReviewsProvider(widget.id), (_, next) {
      if (next.currentUserReview != null && next.currentUserReview!.id.isNotEmpty) {
        if (_currentRatingInput != next.currentUserReview!.rating.toDouble() || _reviewTextController.text != (next.currentUserReview!.text ?? '')) {
            setState(() {
              _currentRatingInput = next.currentUserReview!.rating.toDouble();
              _reviewTextController.text = next.currentUserReview!.text ?? '';
            });
        }
      } else { // No review or review was deleted
         if (_currentRatingInput != 0 || _reviewTextController.text.isNotEmpty) {
           setState(() {
             _currentRatingInput = 0;
             _reviewTextController.clear();
           });
         }
      }
    });


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Avaliações'),
        
        // Average Rating Display
        reviewsState.averageRating.when(
          data: (avgRating) => avgRating != null
              ? Row(
                  children: [
                    _RatingStars(rating: avgRating, size: 24, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '${avgRating.toStringAsFixed(1)} de 5 estrelas',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${reviewsState.reviews.asData?.value.length ?? 0} avaliações)',
                       style: theme.textTheme.bodySmall,
                    )
                  ],
                )
              : const Text('Nenhuma avaliação ainda.', style: TextStyle(fontStyle: FontStyle.italic)),
          loading: () => const SizedBox(height: 24, child: Center(child: SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2,)))),
          error: (e, st) => Text('Erro ao carregar média.', style: TextStyle(color: theme.colorScheme.error)),
        ),
        const SizedBox(height: 16),

        // Review Input/Edit Section
        if (currentUserId.isNotEmpty)
          _buildReviewInputSection(currentUserId, reviewsState.currentUserReview)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Você precisa estar logado para avaliar.', style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant)),
          ),
        
        const SizedBox(height: 16),
        Text("Todas as Avaliações:", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),

        // List of Reviews
        reviewsState.reviews.when(
          data: (reviewsList) {
            if (reviewsList.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Nenhuma avaliação ainda.', style: TextStyle(fontStyle: FontStyle.italic)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviewsList.length,
              itemBuilder: (context, index) {
                final review = reviewsList[index];
                return _ReviewItem(review: review, currentUserId: currentUserId, recipeId: widget.id);
              },
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          error: (error, stackTrace) {
            if (kDebugMode) {
              print('[ReviewsSection Error] $error');
              print('[ReviewsSection StackTrace] $stackTrace');
            }
            return Center(child: Text('Erro ao carregar avaliações: ${error.toString()}', style: TextStyle(color: theme.colorScheme.error)));
          },
        ),
      ],
    );
  }

  Widget _buildReviewInputSection(String currentUserId, app_review.Review? currentUserReview) {
    final theme = Theme.of(context);
    final bool isEditing = currentUserReview != null && currentUserReview.id.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Edite sua Avaliação' : 'Deixe sua Avaliação', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _currentRatingInput ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentRatingInput = (index + 1).toDouble();
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewTextController,
              decoration: InputDecoration(
                hintText: 'Escreva sua avaliação (opcional)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEditing)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir Avaliação?'),
                          content: const Text('Tem certeza que deseja excluir sua avaliação?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await ref.read(recipeReviewsProvider(widget.id).notifier).deleteCurrentUserReview();
                          setState(() { // Reset form
                            _currentRatingInput = 0;
                            _reviewTextController.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Avaliação excluída.'), duration: Duration(seconds: 2)),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao excluir: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    child: Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: (_currentRatingInput == 0) ? null : () { // Disable if no rating
                    _submitReview(currentUserId);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                  child: Text(isEditing ? 'Atualizar' : 'Enviar', style: TextStyle(color: theme.colorScheme.onPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitReview(String currentUserId) {
    if (_currentRatingInput == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma classificação de estrelas.')),
      );
      return;
    }
    final reviewNotifier = ref.read(recipeReviewsProvider(widget.id).notifier);
    reviewNotifier.addOrUpdateReview(
      userId: currentUserId,
      rating: _currentRatingInput.toInt(),
      text: _reviewTextController.text.trim().isEmpty ? null : _reviewTextController.text.trim(),
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação enviada!')),
      );
      // Form reset is handled by the ref.listen in _buildReviewsSection
      FocusScope.of(context).unfocus();
    }).catchError((e) {
      if (kDebugMode) {
        print('Error submitting review from UI: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao enviar avaliação: ${e.toString()}')),
      );
    });
  }
  // END: ADDED FOR REVIEWS

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRecipeState = ref.watch(recipeDetailVmProvider(widget.id));
    final displayTitle = _isEditMode ? _titleController.text : (currentRecipeState.recipe?.name ?? widget.title);
    final recipe = currentRecipeState.recipe;
    final ownerId = widget.ownerId; 
    final isFavorited = recipe?.isFavorite ?? widget.isFavorite;
    final _supabaseClient = Supabase.instance.client;
    final currentUserId = _supabaseClient.auth.currentUser?.id ?? '';
    final bool isOwner = currentUserId.isNotEmpty && ownerId != null && ownerId == currentUserId;

    final ownerProfileAsyncValue = ownerId != null ? ref.watch(anyUserProfileProvider(ownerId)) : null;

    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
            ? TextField(
                controller: _titleController,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'Nome da Receita',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150)),
                  border: InputBorder.none,
                ),
              )
            : Text(displayTitle),
        actions: [
          if (ownerId != null && ownerProfileAsyncValue != null)
            ownerProfileAsyncValue.when(
              data: (profileData) {
                if (profileData == null) return const SizedBox.shrink();
                final avatarUrl = profileData['avatar_url'] as String?;
                return IconButton(
                  icon: CircleAvatar(
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  onPressed: () {
                    context.push('/user/$ownerId');
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, stack) => IconButton(
                icon: const Icon(Icons.error),
                onPressed: () {
                   context.push('/user/$ownerId');
                },
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network( widget.imagePath!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          if (kDebugMode) {
                            print('Error loading network image: ${widget.imagePath}, Exception: $exception');
                          }
                          return Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12), 
                            ),
                            child: Icon(Icons.broken_image, color: Colors.grey[600], size: 50),
                          );
                        },
                      ),
              ),
            if (widget.imagePath == null || widget.imagePath!.isEmpty)
              Container( 
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_camera, color: Colors.grey[600], size: 50),
              ),
            const SizedBox(height: 16),
            if (!_isEditMode) 
              Text(
                displayTitle,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            Padding( 
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: <Widget>[
                  if (!_isEditMode)
                    _buildInfoChip(Icons.timer_outlined, widget.time) 
                  else
                    SizedBox(
                      width: 100, 
                      child: TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(labelText: 'Tempo (min)', border: InputBorder.none),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  const SizedBox(width: 16.0),
                  if (!_isEditMode)
                    _buildInfoChip(Icons.restaurant_outlined, widget.servings) 
                  else
                    SizedBox(
                      width: 100, 
                      child: TextField(
                        controller: _servingsController,
                        decoration: const InputDecoration(labelText: 'Porções', border: InputBorder.none),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border),
                    onPressed: _toggleFavorite,
                    color: isFavorited ? theme.colorScheme.primary : null,
                  ),
                  if (isOwner)
                    IconButton(
                      icon: Icon(_isEditMode ? Icons.check : Icons.edit),
                      onPressed: _toggleEditMode,
                    ),
                ],
              ),
            ),
            _buildSectionTitle('Ingredientes'),
            if (!_isEditMode)
              _buildIngredientsSection()
            else
              TextField( 
                controller: _ingredientsController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Ingredientes',
                  hintText: 'Categoria1:\\n  Item1\\n  Item2\\nCategoria2:\\n  Item3',
                  border: OutlineInputBorder(),
                ),
              ),
            _buildSectionTitle('Modo de Preparo'),
            if (!_isEditMode)
              _buildStepsSection()
            else
              TextField( 
                controller: _stepsController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Modo de Preparo',
                  hintText: 'Passo 1\\nPasso 2',
                  border: OutlineInputBorder(),
                ),
              ),
            
            // BEGIN: ADDED FOR REVIEWS
            if (!_isEditMode)
              _buildReviewsSection(currentUserId),
            // END: ADDED FOR REVIEWS
            
            if (!_isEditMode)
               _buildCommentsSection(currentUserId),

            if (_isEditMode) ...[ 
              const SizedBox(height: 24), 
              Center( 
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, 
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: _confirmDeleteRecipe, 
                  child: const Text('Excluir Receita', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16), 
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentItem extends ConsumerWidget {
  final Comment comment;
  final String currentUserId;
  final String recipeId;

  const _CommentItem({
    required this.comment,
    required this.currentUserId,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool isAuthor = comment.userId == currentUserId;
    final authorProfileAsync = ref.watch(anyUserProfileProvider(comment.userId));

    return Card( 
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                authorProfileAsync.when(
                  data: (profileData) {
                    final avatarUrl = profileData?['avatar_url'] as String?;
                    final userName = profileData?['name'] as String? ?? 'Usuário Anônimo'; // Corrected
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height:36, child: Row(children:[CircleAvatar(radius:18), SizedBox(width:8), Text("Carregando...")])),
                  error: (e, st) => Row(children:[const CircleAvatar(radius:18, child: Icon(Icons.error, size:18)), SizedBox(width:8), Text(comment.userName ?? 'Usuário Anônimo', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))]),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yy HH:mm').format(comment.createdAt.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (isAuthor) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Excluir comentário',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>( 
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir Comentário?'),
                          content: const Text('Tem certeza que deseja excluir este comentário?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                           await ref.read(recipeCommentsProvider(recipeId).notifier).deleteComment(commentId: comment.id);
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Comentário excluído.'), duration: Duration(seconds: 2)),
                           );
                        } catch (e) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Erro ao excluir: ${e.toString()}'), duration: Duration(seconds: 2)),
                           );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.text,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// BEGIN: ADDED FOR REVIEWS
class _RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const _RatingStars({required this.rating, this.size = 20.0, this.color = Colors.amber});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData iconData;
        if (index < rating.floor()) {
          iconData = Icons.star;
        } else if (index < rating && (rating - index) >= 0.5) {
          iconData = Icons.star_half;
        } else {
          iconData = Icons.star_border;
        }
        return Icon(iconData, size: size, color: color);
      }),
    );
  }
}

class _ReviewItem extends ConsumerWidget {
  final app_review.Review review; // Use alias
  final String currentUserId;
  final int recipeId; // recipeId is int

  const _ReviewItem({
    required this.review,
    required this.currentUserId,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authorProfileAsync = ref.watch(anyUserProfileProvider(review.userId));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                authorProfileAsync.when(
                  data: (profileData) {
                    final avatarUrl = profileData?['avatar_url'] as String?;
                    final userName = profileData?['name'] as String? ?? 'Usuário Anônimo'; // Corrected
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height:36, child: Row(children:[CircleAvatar(radius:18), SizedBox(width:8), Text("Carregando...")])),
                  error: (e, st) => Row(children:[const CircleAvatar(radius:18, child: Icon(Icons.error, size:18)), SizedBox(width:8), Text(review.userName ?? 'Usuário Anônimo', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))]),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                     _RatingStars(rating: review.rating.toDouble(), size: 16),
                     const SizedBox(height: 4),
                     Text(
                      DateFormat('dd/MM/yy HH:mm').format(review.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                )
              ],
            ),
            if (review.text != null && review.text!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.text!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
// END: ADDED FOR REVIEWS
