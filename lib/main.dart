
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase pehle
  await Supabase.initialize(
    url: 'https://kjjtqfruxhjcxwvxwffz.supabase.co',
    anonKey: 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS',
  );

  // 2. Config load
  await AppConfig.load();

  // 3. DB connect
  await DatabaseService.getConnection();

  // 4. Sync start — DB aur Supabase dono ready hain
  WarehouseSupabaseSyncService.instance.start(
    interval: const Duration(minutes: 1),
  );

  // 5. App run
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
      return const SideBar();
    }

    // Not logged in → Login Screen
    return const LoginScreen();
  }
}


////////////////////////////////////////////////////////////////////////////////////
// ==== //////// /////// ////// BELOW CODE IS FOR MOBILE === //////// /////// //////
////////////////////////////////////////////////////////////////////////////////////




// import 'dart:io' if (dart.library.html) 'package:jan_ghani_final/core/stub/io_stub.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:jan_ghani_final/core/service/db/db_service.dart';
// import 'package:jan_ghani_final/core/theme/light_theme.dart';
// import 'package:jan_ghani_final/features/accountant/authentication/presentation/screen/login_screen.dart';
// import 'package:jan_ghani_final/features/accountant/dashboard/presentation/screen/dashboard_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../core/config/store_config.dart';
// import '../core/service/session/accountant_session.dart';
// import '../core/service/sync/sync_service.dart';
// import '../features/branch/authentication/presentation/provider/auth_provider.dart';
// import 'core/widget/sidebar/branch_sidebar_widget.dart';
// import 'features/branch/authentication/presentation/screen/login_screen.dart';
//
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
//     url: 'https://kjjtqfruxhjcxwvxwffz.supabase.co',
//     anonKey: 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS',
//     realtimeClientOptions: const RealtimeClientOptions(
//       logLevel: RealtimeLogLevel.info,
//     ),
//   );
//   await SharedPreferences.getInstance();
//
//   // await StoreConfig.load();
//   // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//   //   SyncService().start();
//   //   DataBaseService.getConnection();
//   // }
//   final prefs = await SharedPreferences.getInstance();
//   print('ACC ID: ${prefs.getString('acc_id')}');
//   final loggedIn = await AccountantSession.isLoggedIn();
//
//   runApp(ProviderScope(child: MyApp(isLoggedIn: loggedIn,)));
// }
//
// class MyApp extends ConsumerWidget {
//   final bool isLoggedIn;
//   const MyApp({this.isLoggedIn = false,super.key});
//
//   @override
//   Widget build(BuildContext context,WidgetRef ref) {
//     final auth = ref.watch(authProvider);
//     String? customerId;
//     if (kIsWeb) {
//       final path = Uri.base.path;
//       final id   = path.replaceFirst('/', '').trim();
//       if (id.isNotEmpty) customerId = id;
//     }
//     return ProviderScope(
//       child: MaterialApp(
//         title: 'Jan Ghani',
//         debugShowCheckedModeBanner: false,
//         theme: LightTheme.theme,
//         home: isLoggedIn ? AccountantDashboardScreen() : AccountantLoginScreen(),
//         // home:
//         // CustomerVerificationScreen(
//         //   customerId: customerId!,
//         // )
//       //   auth.isLoading ?
//       //   Scaffold(
//       //     body: const CircularProgressIndicator(),
//       //   ) :
//       //   auth.isLoggedIn ? const BranchSideBar() : const LoginScreen(),
//       ),
//     );
//   }
// }