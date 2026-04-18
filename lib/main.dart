import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/core/service/warehouse_supabase_sync_service/warehouse_supabase_sync_service.dart';
import 'package:jan_ghani_final/core/theme/light_theme.dart';
import 'package:jan_ghani_final/core/widget/sidebar/branch_sidebar_widget.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/store_config.dart';
import 'core/service/db/db_service.dart';
import 'core/service/stock_assign_services/stock_transfer_sync_provider.dart';
import 'core/service/sync/sync_service.dart';
import 'core/widget/sidebar/sidebar_widget.dart';

final syncService = SyncService();
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase pehle
  await Supabase.initialize(
    url: 'https://kjjtqfruxhjcxwvxwffz.supabase.co',
    anonKey: 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS',
  );

  await SharedPreferences.getInstance();
  await StoreConfig.load();
  DataBaseService.getConnection();
  await syncService.startSync();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jan Ghani Warehouse',
      debugShowCheckedModeBanner: false,
      theme: LightTheme.theme,
      home: const _AuthWrapper(),
    );
  }
}

// ── Auth Wrapper ──────────────────────────────────────────────
class _AuthWrapper extends ConsumerWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ADD 2 — Sync service start karo (sirf ek baar)
    ref.watch(stockTransferSyncServiceProvider);

    final auth = ref.watch(authProvider);

    // Loading
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Logged in → SideBar
    if (auth.isLoggedIn) {
      return const BranchSideBar();
    }

    // Not logged in → Login Screen
    return const LoginScreen();
  }
}