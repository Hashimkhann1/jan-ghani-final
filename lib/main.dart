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
    return MaterialApp(
        title: 'Jan Ghani',
        debugShowCheckedModeBanner: false,
        theme: LightTheme.theme,
      // Website → Accountant. Desktop (Windows/Mac) → Branch
      // (Warehouse ka apna alag entry point hai: lib/main_warehouse.dart).
      home: kIsWeb ? const _AccountantHome() : const _BranchHome(),
    );
  }
}

// ── Web: Accountant ─────────────────────────────────────────────
class _AccountantHome extends ConsumerWidget {
  const _AccountantHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    if (session.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (session.user != null) {
      return const AccountantDashboardScreen();
    }

    return const AccountantLoginScreen();
  }
}

// ── Desktop: Branch ──────────────────────────────────────────────
class _BranchHome extends ConsumerWidget {
  const _BranchHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // ── Loading / checking ──
    if (auth.isLoading || (auth.hasBranch == null && !auth.checkFailed)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── DB reachable nahi — retry, warna setup screen pe mat bhejo ──
    if (auth.checkFailed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 12),
              const Text('Database se connect nahi ho saka'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(authProvider.notifier).retryInit(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Branch nahi hai local DB mein ──
    if (!auth.hasBranch!) {
      return const BackupScreen();
    }

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
// jan_ghani_final.exe > logs.txt 2>&1