// NOTE: Warehouse app ka entry point ab lib/main_warehouse.dart mein hai
// (flutter run -t lib/main_warehouse.dart). Yeh file (main.dart) sirf
// Branch/Accountant app ke liye hai.

import 'dart:io' if (dart.library.html) 'package:jan_ghani_final/core/stub/io_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/theme/light_theme.dart';
import 'package:jan_ghani_final/features/branch/backup/presentation/screen/branch_backup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../core/service/session/accountant_session.dart';
import '../features/branch/authentication/presentation/provider/auth_provider.dart';
import 'core/config/store_config.dart';
import 'core/service/db/db_service.dart';
import 'core/service/sync/sync_service.dart';
import 'core/widget/sidebar/branch_sidebar_widget.dart';
import 'features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';

import 'features/accountant/authentication/presentation/screen/login_screen.dart';
import 'features/accountant/dashboard/presentation/screen/dashboard_screen.dart';
import 'features/branch/authentication/presentation/screen/login_screen.dart';

final supabase = Supabase.instance.client;

final accountantSessionCheckProvider = FutureProvider<bool>((ref) async {
  return AccountantSession.isLoggedIn();
});

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url:
    // "https://fngvbieiwilypecznwcl.supabase.co",
    "https://kjjtqfruxhjcxwvxwffz.supabase.co",
    anonKey:
    // "sb_publishable_z-6QD20dfck8hoG9_NzSZw_063NHmS4",
    "sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS",
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );
  await SharedPreferences.getInstance();

  await StoreConfig.load();
  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      SyncService().start();
      DataBaseService.getConnection();
    }
  }
  runApp(ProviderScope(child: MyApp()));

}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session  = ref.watch(sessionProvider).user?.id ?? "";
    final auth = ref.watch(authProvider);
    return MaterialApp(
        title: 'Jan Ghani',
        debugShowCheckedModeBanner: false,
        theme: LightTheme.theme,
      home:
      // session.isEmpty ? AccountantLoginScreen() : AccountantDashboardScreen()
      // InventoryCountingScreen(),
      // session.isEmpty ? AccountantLoginScreen() :
      // AccountantDashboardScreen()
      _resolveHome(session, auth),
    );
  }


  Widget _resolveHome(String session, AuthState auth) {
    // ── Loading / checking ──
    if (auth.isLoading || auth.hasBranch == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── Branch nahi hai local DB mein ──
    if (!auth.hasBranch!) {
      return const BackupScreen();
    }



    // ── Accountant logged in ──
    // if (session.isNotEmpty) {
    //   return AccountantDashboardScreen();
    // }

    // ── Branch user logged in ──
    if (auth.isLoggedIn) {
      return const BranchSideBar();
    }

    // ── Koi nahi logged in ──
    return const LoginScreen();
  }
}


// git tag v1.0.0
// git push origin v1.0.0