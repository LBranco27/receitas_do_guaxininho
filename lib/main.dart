import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/app_theme.dart';
import 'data/datasources/recipe_local_datasource.dart';
import 'data/repositories/recipe_repository_impl.dart';
import 'features/recipes/view/create_recipe_page.dart';
import 'features/recipes/view/home_page.dart';
import 'features/recipes/view/recipe_detail_page.dart';
import 'features/recipes/viewmodel/home_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await RecipeLocalDataSource().seedIfEmpty();

  runApp(
    ProviderScope(
      overrides: [
        recipeRepositoryProvider.overrideWith(
              (ref) => RecipeRepositoryImpl(RecipeLocalDataSource()),
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

//class MyHomePage extends StatefulWidget {
//  const MyHomePage({super.key, required this.title});
//
//  final String title;
//
//  @override
//  State<MyHomePage> createState() => _MyHomePageState();
//}
//
//class _MyHomePageState extends State<MyHomePage> {
//  void _navigateToRecipePage(BuildContext context) {
//    Navigator.push(
//      context,
//      MaterialPageRoute(
//        builder: (context) => const RecipePage(
//          title: "Martini de Morango",
//          imagePath: "assets/images/martini_de_morango.png",
//          time: "5 min",
//          servings: "1 pessoa",
//          ingredients: {
//            "Martini": "200ml de martini de preferência",
//            "Morango": "100g de morangos selecionados à mão por himalios",
//          },
//          preparationSteps: [
//            "Esmague os morangos com suas mãos.",
//            "Coloque os morangos totalmente esmagados em um recipiente (podendo ser uma taça).",
//            "Adicione o martini e misture a bebida com sua mão (esmague pedaços grandes de morango se precisar).",
//          ],
//        ),
//      ),
//    );
//  }