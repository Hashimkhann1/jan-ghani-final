import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/service/db/db_service.dart';
import 'package:jan_ghani_final/core/theme/light_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/store_config.dart';
import 'core/service/session/accountant_session.dart';
import 'core/service/sync/sync_service.dart';
import 'features/accountant/authentication/presentation/screen/login_screen.dart';
import 'features/accountant/dashboard/presentation/screen/dashboard_screen.dart';
import 'features/branch/authentication/presentation/provider/auth_provider.dart';

final supabase = Supabase.instance.client;
final syncService = SyncService();

final accountantSessionCheckProvider = FutureProvider<bool>((ref) async {
  return AccountantSession.isLoggedIn();
});

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kjjtqfruxhjcxwvxwffz.supabase.co',
    anonKey: 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS',
  );
  await SharedPreferences.getInstance();
  await StoreConfig.load();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await syncService.start();
    DataBaseService.getConnection();
  }
  final prefs = await SharedPreferences.getInstance();
  print('ACC ID: ${prefs.getString('acc_id')}');
  final loggedIn = await AccountantSession.isLoggedIn();

  runApp(ProviderScope(child: MyApp(isLoggedIn: loggedIn,)));
}

class MyApp extends ConsumerWidget {
  final bool isLoggedIn;
  const MyApp({required this.isLoggedIn,super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return ProviderScope(
      child: MaterialApp(
        title: 'Jan Ghani',
        debugShowCheckedModeBanner: false,
        theme: LightTheme.theme,
        home: isLoggedIn
            ? const AccountantDashboardScreen()
            : const AccountantLoginScreen(),
        // auth.isLoading ?
        // Scaffold(
        //   body: const CircularProgressIndicator(),
        // ) :
        // auth.isLoggedIn ?
        // const BranchSideBar() :
        // const LoginScreen(),
      ),
    );
  }
}





