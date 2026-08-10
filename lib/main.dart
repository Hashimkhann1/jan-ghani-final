import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/core/service/warehouse_supabase_sync_service/warehouse_supabase_sync_service.dart';
import 'package:jan_ghani_final/core/theme/light_theme.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/service/stock_assign_services/stock_transfer_sync_provider.dart';
import 'core/widget/sidebar/sidebar_widget.dart';

/// true sirf jab TESTING Supabase use ho raha ho.
/// Neeche testing block ise `true` karta hai; production block kuch nahi karta
/// (default false) → production par koi banner nahi dikhta.
bool kIsTestingDatabase = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase pehle

// ////////////////////////////////////
// // BELOW IS TESTING SUPABASE IDS ////
// ////////////////////////////////////
//
//   await Supabase.initialize(
//     url: 'https://fngvbieiwilypecznwcl.supabase.co',
//     anonKey: 'sb_publishable_z-6QD20dfck8hoG9_NzSZw_063NHmS4',
//     realtimeClientOptions: const RealtimeClientOptions(
//       logLevel: RealtimeLogLevel.info,
//     ),
//   );
//   kIsTestingDatabase = true; // ← TESTING DB active (banner dikhega)
//
// ////////////////////////////////////////////////
// /////// BELOW IS THE PRODUCTION DB IDS /////////
// ////////////////////////////////////////////////

  await Supabase.initialize(
    url: 'https://kjjtqfruxhjcxwvxwffz.supabase.co',
    anonKey: 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS',
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );
  kIsTestingDatabase = false; // ← PRODUCTION DB active (koi banner nahi)

////////////////////////////////////////////////
////////////////////////////////////////////////
////////////////////////////////////////////////

  // 2. Config load
  await AppConfig.load();

  // 3. DB connect
  await DatabaseService.getConnection();

  // 4. Sync start — DB aur Supabase dono ready hain
  WarehouseSupabaseSyncService.instance.start(
    interval: const Duration(minutes: 1),
  );

  // 5. App run
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
      builder: (context, child) {
        if (!kIsTestingDatabase) return child!;
        // Sirf testing DB par — top center mein chhota sa chip
        return Stack(
          textDirection: TextDirection.ltr,
          children: [
            Positioned.fill(child: child!),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Working in the Testing Database',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Logged in → SideBar
    if (auth.isLoggedIn) {
      return const SideBar();
    }

    // Not logged in → Login Screen
    return const LoginScreen();
  }
}


// import 'dart:io' if (dart.library.html) 'package:jan_ghani_final/core/stub/io_stub.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:jan_ghani_final/core/theme/light_theme.dart';
// import 'package:jan_ghani_final/features/branch/backup/presentation/screen/branch_backup_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
// import '../core/service/session/accountant_session.dart';
// import '../features/branch/authentication/presentation/provider/auth_provider.dart';
// import 'core/config/store_config.dart';
// import 'core/service/db/db_service.dart';
// import 'core/service/sync/sync_service.dart';
// import 'core/widget/sidebar/branch_sidebar_widget.dart';
// import 'features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';
// import 'features/accountant/authentication/presentation/screen/login_screen.dart';
// import 'features/accountant/dashboard/presentation/screen/dashboard_screen.dart';
// import 'features/branch/authentication/presentation/screen/login_screen.dart';
//
// final supabase = Supabase.instance.client;
//
// final accountantSessionCheckProvider = FutureProvider<bool>((ref) async {
//   return AccountantSession.isLoggedIn();
// });
//
// void main() async{
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url:
//     // "https://fngvbieiwilypecznwcl.supabase.co",
//     "https://kjjtqfruxhjcxwvxwffz.supabase.co",
//     anonKey:
//     // "sb_publishable_z-6QD20dfck8hoG9_NzSZw_063NHmS4",
//     "sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS",
//     realtimeClientOptions: const RealtimeClientOptions(
//       logLevel: RealtimeLogLevel.info,
//     ),
//   );
//   await SharedPreferences.getInstance();
//
//   await StoreConfig.load();
//   if (!kIsWeb) {
//     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//       SyncService().start();
//       DataBaseService.getConnection();
//     }
//   }
//   runApp(ProviderScope(child: MyApp()));
//
// }
//
// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final session  = ref.watch(sessionProvider).user?.id ?? "";
//     final auth = ref.watch(authProvider);
//     return MaterialApp(
//         title: 'Jan Ghani',
//         debugShowCheckedModeBanner: false,
//         theme: LightTheme.theme,
//         home:
//         // InventoryCountingScreen(),
//         session.isEmpty ? AccountantLoginScreen() : AccountantDashboardScreen()
//       // _resolveHome(session, auth),
//     );
//   }
//
//
//   Widget _resolveHome(String session, AuthState auth) {
//     // ── Loading / checking ──
//     if (auth.isLoading || auth.hasBranch == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     // ── Branch nahi hai local DB mein ──
//     if (!auth.hasBranch!) {
//       return const BackupScreen();
//     }
//
//
//
//     // ── Accountant logged in ──
//     // if (session.isNotEmpty) {
//     //   return AccountantDashboardScreen();
//     // }
//
//     // ── Branch user logged in ──
//     if (auth.isLoggedIn) {
//       return const BranchSideBar();
//     }
//
//     // ── Koi nahi logged in ──
//     return const LoginScreen();
//   }
// }


// git tag v1.0.0
// git push origin v1.0.0