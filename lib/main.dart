import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/pb_client.dart';
import 'models/category.dart';
import 'models/category_query.dart';
import 'models/client.dart';
import 'models/client_query.dart';
import 'models/designer.dart';
import 'models/designer_query.dart';
import 'models/manufacturer.dart';
import 'models/manufacturer_query.dart';
import 'models/store.dart';
import 'models/store_query.dart';
import 'models/weapon.dart';
import 'models/weapon_query.dart';
import 'repositories/admin_api.dart';
import 'repositories/category_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/designer_repository.dart';
import 'repositories/license_repository.dart';
import 'repositories/manufacturer_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/pb_category_repository.dart';
import 'repositories/pb_client_repository.dart';
import 'repositories/pb_designer_repository.dart';
import 'repositories/pb_license_repository.dart';
import 'repositories/pb_manufacturer_repository.dart';
import 'repositories/pb_order_repository.dart';
import 'repositories/pb_store_repository.dart';
import 'repositories/pb_weapon_repository.dart';
import 'repositories/store_repository.dart';
import 'repositories/weapon_repository.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final pb = await buildPocketBase(prefs);
  final authNotifier = AuthNotifier(prefs, pb);
  await authNotifier.restore();

  final router = buildRouter(authNotifier);

  runApp(ArmoryApp(pb: pb, authNotifier: authNotifier, router: router));
}

class ArmoryApp extends StatelessWidget {
  const ArmoryApp({
    super.key,
    required this.pb,
    required this.authNotifier,
    required this.router,
  });

  final PocketBase pb;
  final AuthNotifier authNotifier;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<PocketBase>.value(value: pb),
        ProxyProvider<PocketBase, WeaponRepository>(
          update: (_, pb, _) => PbWeaponRepository(pb),
        ),
        ProxyProvider<PocketBase, ManufacturerRepository>(
          update: (_, pb, _) => PbManufacturerRepository(pb),
        ),
        ProxyProvider<PocketBase, CategoryRepository>(
          update: (_, pb, _) => PbCategoryRepository(pb),
        ),
        ProxyProvider<PocketBase, DesignerRepository>(
          update: (_, pb, _) => PbDesignerRepository(pb),
        ),
        ProxyProvider<PocketBase, StoreRepository>(
          update: (_, pb, _) => PbStoreRepository(pb),
        ),
        ProxyProvider<PocketBase, ClientRepository>(
          update: (_, pb, _) => PbClientRepository(pb),
        ),
        ProxyProvider<PocketBase, LicenseRepository>(
          update: (_, pb, _) => PbLicenseRepository(pb),
        ),
        ProxyProvider<PocketBase, OrderRepository>(
          update: (_, pb, _) => PbOrderRepository(pb),
        ),
        ProxyProvider<PocketBase, AdminApi>(update: (_, pb, _) => AdminApi(pb)),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Weapon, WeaponQuery>(
            context.read<WeaponRepository>(),
            const WeaponQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Manufacturer, ManufacturerQuery>(
            context.read<ManufacturerRepository>(),
            const ManufacturerQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Category, CategoryQuery>(
            context.read<CategoryRepository>(),
            const CategoryQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Designer, DesignerQuery>(
            context.read<DesignerRepository>(),
            const DesignerQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Store, StoreQuery>(
            context.read<StoreRepository>(),
            const StoreQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Client, ClientQuery>(
            context.read<ClientRepository>(),
            const ClientQuery(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
          return MaterialApp.router(
            title: 'Оружейный магазин',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: Colors.blueGrey,
              useMaterial3: true,
            ),
            routerConfig: router,
            scaffoldMessengerKey: scaffoldMessengerKey,
            builder: (context, child) => Consumer<AuthNotifier>(
              builder: (context, auth, _) => InactivityWatcher(
                timeout: const Duration(minutes: 3),
                warnBefore: const Duration(seconds: 30),
                enabled: auth.isAuthenticated,
                onWarn: () => scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Сессия завершится через 30 секунд из-за неактивности',
                    ),
                    duration: Duration(seconds: 10),
                  ),
                ),
                onTimeout: () =>
                    auth.logout(reason: 'Сессия завершена по неактивности.'),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
