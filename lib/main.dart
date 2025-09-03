import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
//import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
//import 'data/datasources/recipe_local_datasource.dart';
import 'data/datasources/recipe_remote_datasource.dart';
import 'data/repositories/recipe_repository_impl.dart';
import 'features/recipes/view/create_recipe_page.dart';
import 'features/recipes/view/home_page.dart';
import 'features/recipes/view/recipe_detail_page.dart';
import 'features/recipes/viewmodel/home_viewmodel.dart';

const supabaseUrl = 'https://sgyzhbcauskbaknoimtu.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //sqfliteFfiInit();
  //databaseFactory = databaseFactoryFfi;

  // using supabase instead of local sqlite
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

//  await RecipeRemoteDataSource().seedIfEmpty();

  runApp(
    ProviderScope(
      overrides: [
        recipeRepositoryProvider.overrideWith(
              //(ref) => RecipeRepositoryImpl(RecipeLocalDataSource()),
              (ref) => RecipeRepositoryImpl(RecipeRemoteDataSource()),
        ),
      ],
      child: const RecipesApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'recipe/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return RecipeDetailPage(id: id);
          },
        ),
        GoRoute(
          path: 'create',
          builder: (context, state) => const CreateRecipePage(),
        ),
      ],
    ),
  ],
);

class RecipesApp extends StatelessWidget {
  const RecipesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Receitas do Guaxinim',
      theme: appTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}