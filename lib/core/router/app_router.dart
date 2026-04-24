import 'package:dualio/features/auth/presentation/sign_in_screen.dart';
import 'package:dualio/features/categories/presentation/categories_screen.dart';
import 'package:dualio/features/capture/presentation/add_item_screen.dart';
import 'package:dualio/features/feed/presentation/screens/feed_screen.dart';
import 'package:dualio/features/items/presentation/item_detail_screen.dart';
import 'package:dualio/features/search/presentation/search_screen.dart';
import 'package:dualio/features/settings/presentation/settings_screen.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/add', builder: (context, state) => const AddItemScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: '/items/:id',
        builder: (context, state) => ItemDetailScreen(itemId: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
}
