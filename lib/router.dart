import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/category_query.dart';
import 'models/client_query.dart';
import 'models/designer_query.dart';
import 'models/manufacturer_query.dart';
import 'models/role.dart';
import 'models/store_query.dart';
import 'models/weapon_query.dart';
import 'screens/admin/admin_screen.dart' deferred as admin_lib;
import 'screens/auth/forbidden_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/categories/category_detail_screen.dart';
import 'screens/categories/category_list_screen.dart';
import 'screens/clients/client_detail_screen.dart';
import 'screens/clients/client_list_screen.dart';
import 'screens/deferred_forms.dart' deferred as forms_lib;
import 'screens/designers/designer_detail_screen.dart';
import 'screens/designers/designer_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manufacturers/manufacturer_detail_screen.dart';
import 'screens/manufacturers/manufacturer_list_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/stores/store_detail_screen.dart';
import 'screens/stores/store_list_screen.dart';
import 'screens/weapons/weapon_detail_screen.dart';
import 'screens/weapons/weapon_list_screen.dart';
import 'state/auth_notifier.dart';

const _publicPaths = {'/login', '/register'};

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      if (auth.isRestoring) return null;

      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = _publicPaths.contains(target);

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),

      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => _DeferredScreen(
          loadLibrary: admin_lib.loadLibrary,
          build: () => admin_lib.AdminScreen(),
        ),
        redirect: (context, state) =>
            auth.has(Role.admin) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/weapons',
        builder: (context, state) => WeaponListScreen(
          query: WeaponQuery.fromQueryParameters(state.uri.queryParameters),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => _DeferredScreen(
              loadLibrary: forms_lib.loadLibrary,
              build: () => forms_lib.WeaponFormScreen(),
            ),
            redirect: (context, state) =>
                auth.has(Role.seller) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                WeaponDetailScreen(id: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => _DeferredScreen(
                  loadLibrary: forms_lib.loadLibrary,
                  build: () => forms_lib.WeaponFormScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
                redirect: (context, state) =>
                    auth.has(Role.seller) ? null : '/forbidden',
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/manufacturers',
        builder: (context, state) => ManufacturerListScreen(
          query: ManufacturerQuery.fromQueryParameters(
            state.uri.queryParameters,
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => _DeferredScreen(
              loadLibrary: forms_lib.loadLibrary,
              build: () => forms_lib.ManufacturerFormScreen(),
            ),
            redirect: (context, state) =>
                auth.has(Role.seller) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => ManufacturerDetailScreen(
              id: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => _DeferredScreen(
                  loadLibrary: forms_lib.loadLibrary,
                  build: () => forms_lib.ManufacturerFormScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
                redirect: (context, state) =>
                    auth.has(Role.seller) ? null : '/forbidden',
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => CategoryListScreen(
          query: CategoryQuery.fromQueryParameters(state.uri.queryParameters),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => _DeferredScreen(
              loadLibrary: forms_lib.loadLibrary,
              build: () => forms_lib.CategoryFormScreen(),
            ),
            redirect: (context, state) =>
                auth.has(Role.seller) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => CategoryDetailScreen(
              id: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => _DeferredScreen(
                  loadLibrary: forms_lib.loadLibrary,
                  build: () => forms_lib.CategoryFormScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
                redirect: (context, state) =>
                    auth.has(Role.seller) ? null : '/forbidden',
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/designers',
        builder: (context, state) => DesignerListScreen(
          query: DesignerQuery.fromQueryParameters(state.uri.queryParameters),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => _DeferredScreen(
              loadLibrary: forms_lib.loadLibrary,
              build: () => forms_lib.DesignerFormScreen(),
            ),
            redirect: (context, state) =>
                auth.has(Role.seller) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => DesignerDetailScreen(
              id: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => _DeferredScreen(
                  loadLibrary: forms_lib.loadLibrary,
                  build: () => forms_lib.DesignerFormScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
                redirect: (context, state) =>
                    auth.has(Role.seller) ? null : '/forbidden',
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/stores',
        builder: (context, state) => StoreListScreen(
          query: StoreQuery.fromQueryParameters(state.uri.queryParameters),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => _DeferredScreen(
              loadLibrary: forms_lib.loadLibrary,
              build: () => forms_lib.StoreFormScreen(),
            ),
            redirect: (context, state) =>
                auth.has(Role.seller) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                StoreDetailScreen(id: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => _DeferredScreen(
                  loadLibrary: forms_lib.loadLibrary,
                  build: () => forms_lib.StoreFormScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
                redirect: (context, state) =>
                    auth.has(Role.seller) ? null : '/forbidden',
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => ClientListScreen(
          query: ClientQuery.fromQueryParameters(state.uri.queryParameters),
        ),
        redirect: (context, state) =>
            auth.has(Role.seller) ? null : '/forbidden',
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                ClientDetailScreen(id: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => _DeferredScreen(
                  loadLibrary: forms_lib.loadLibrary,
                  build: () => forms_lib.ClientFormScreen(
                    id: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}

class _DeferredScreen extends StatefulWidget {
  const _DeferredScreen({required this.loadLibrary, required this.build});

  final Future<void> Function() loadLibrary;
  final Widget Function() build;

  @override
  State<_DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<_DeferredScreen> {
  late final Future<void> _loaded = widget.loadLibrary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loaded,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.build();
      },
    );
  }
}
