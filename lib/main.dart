import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
//import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'core/app_theme.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/view/login_page.dart';
import 'features/auth/viewmodel/login_viewmodel.dart';
import 'features/auth/view/register_page.dart';
import 'features/auth/viewmodel/register_viewmodel.dart';
//import 'data/datasources/recipe_local_datasource.dart';
import 'data/datasources/recipe_remote_datasource.dart';
import 'data/repositories/recipe_repository_impl.dart';
import 'features/recipes/view/create_recipe_page.dart';
import 'features/recipes/view/home_page.dart';
import 'features/recipes/view/recipe_detail_page.dart';
import 'features/recipes/viewmodel/home_viewmodel.dart';


const supabaseUrl = 'https://sgyzhbcauskbaknoimtu.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  //sqfliteFfiInit();
  //databaseFactory = databaseFactoryFfi;

  if (dotenv.env['SUPABASE_KEY'] == null) {
    throw Exception("SUPABASE_KEY not found in .env file");
  }
  // using supabase instead of local sqlite
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

//  await RecipeRemoteDataSource().seedIfEmpty();
 runApp( ProviderScope(
      overrides: [
        recipeRepositoryProvider.overrideWith(
              //(ref) => RecipeRepositoryImpl(RecipeLocalDataSource()),
              (ref) => RecipeRepositoryImpl(RecipeRemoteDataSource()),
        ),
        authRepositoryProvider.overrideWith(
              (ref) => AuthRepositoryImpl(ref.watch(supabaseClientProvider)),
        ),
      ],
      child: const RecipesApp(),
    ),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class RecipesApp extends ConsumerWidget {
  const RecipesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    final router = GoRouter(
      refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.stream)),
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
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
      redirect: (context, state) {
        final isLoggedIn = authState.value != null;

        final isLoggingIn = state.matchedLocation == '/login';
        final isRegistering = state.matchedLocation == '/register';

        if (!isLoggedIn && !isLoggingIn && !isRegistering) {
          return '/login';
        }

        if (isLoggedIn && (isLoggingIn || isRegistering)) {
          return '/';
        }

        return null;
      },
    );

    return MaterialApp.router(
      title: 'Receitas do Guaxinim',
      theme: appTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}