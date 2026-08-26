// Warehouse app ka entry point — build/run karne ke liye:
//   flutter run -t lib/main_warehouse.dart
//
// Yeh pehle lib/main.dart ke top par commented-out padi thi (isi wajah se
// warehouse app is codebase se actually build/run hi nahi ho pa rahi thi,
// aur stockTransferSyncServiceProvider — jo branch ke accept/reject par
// warehouse ka stock deduct/reservation-release karta hai — kabhi start
// hi nahi hoti thi). Ab ek alag entry file mein taake lib/main.dart
// (branch/accountant app) bilkul untouched rahe.
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
bool kIsTestingDatabase = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase pehle
  await Supabase.initialize(
    url: 'https://kjjtqfruxhjcxwvxwffz.supabase.co',
    anonKey: 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS',
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );
  kIsTestingDatabase = false; // ← PRODUCTION DB active (koi banner nahi)

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
    // Sync service start karo (sirf ek baar) — missed-transfer catch-up +
    // realtime accept/reject listener, taake warehouse stock automatically
    // deduct/reservation-release ho.
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
