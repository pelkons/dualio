import 'package:dualio/features/auth/presentation/sign_in_screen.dart';
import 'package:dualio/features/categories/presentation/categories_screen.dart';
import 'package:dualio/features/capture/presentation/add_item_screen.dart';
import 'package:dualio/features/feed/presentation/screens/feed_screen.dart';
import 'package:dualio/features/items/presentation/item_detail_screen.dart';
import 'package:dualio/features/search/presentation/search_screen.dart';
import 'package:dualio/features/settings/presentation/settings_screen.dart';
import 'package:dualio/features/share_intake/presentation/share_confirm_screen.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final uri = state.uri;
      final isCustomSchemeCallback =
          uri.scheme == 'dualio' &&
          uri.host == 'auth' &&
          uri.path.startsWith('/callback');
      final isPathCallback = uri.path.startsWith('/auth/callback');
      if (isCustomSchemeCallback || isPathCallback) {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(path: '/add', builder: (context, state) => const AddItemScreen()),
      GoRoute(
        path: '/share-confirm',
        builder: (context, state) => const ShareConfirmScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/items/:id',
        builder: (context, state) =>
            ItemDetailScreen(itemId: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
}
