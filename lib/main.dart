// import 'dart:io';
// import 'dart:io';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/service/db/db_service.dart';
import 'package:jan_ghani_final/core/theme/light_theme.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/screen/login_screen.dart';
import 'package:jan_ghani_final/features/accountant/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/store_config.dart';
import '../core/service/session/accountant_session.dart';
import '../core/service/sync/sync_service.dart';
import '../features/branch/authentication/presentation/provider/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/widget/sidebar/branch_sidebar_widget.dart';
import 'features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';
import 'features/branch/authentication/presentation/screen/login_screen.dart';


final supabase = Supabase.instance.client;

final accountantSessionCheckProvider = FutureProvider<bool>((ref) async {
  return AccountantSession.isLoggedIn();
});

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: '.env');
  // final String _grokApiKey = dotenv.env['GROK_API_KEY'] ?? '';
  // print(_grokApiKey);
  await Supabase.initialize(
    url: 'https://kjjtqfruxhjcxwvxwffz.supabase.co',
    anonKey: 'sb_publishable_MCed-D-zAvYgkZmwYadWCw__eZw_zdS',
  );
  await SharedPreferences.getInstance();
  await StoreConfig.load();
  // if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //   SyncService().start();
  //   DataBaseService.getConnection();
  // }

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = ref.watch(sessionProvider);
    return ProviderScope(
      child: MaterialApp(
        title: 'Jan Ghani',
        debugShowCheckedModeBanner: false,
        theme: LightTheme.theme,
        home: user?.id.isEmpty == true ? AccountantDashboardScreen() : AccountantLoginScreen()
        // auth.isLoading ?
        // Scaffold(
        //   body: const CircularProgressIndicator(),
        // ) :
        // auth.isLoggedIn ? const BranchSideBar() : const LoginScreen(),
      ),
    );
  }
}