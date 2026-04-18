import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/service/db/db_service.dart';
import 'package:jan_ghani_final/core/theme/light_theme.dart';
import 'package:jan_ghani_final/core/widget/sidebar/branch_sidebar_widget.dart';
import 'package:jan_ghani_final/features/branch/authentication/presentation/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/store_config.dart';
import 'core/service/sync/sync_service.dart';
import 'core/widget/sidebar/sidebar_widget.dart';
import 'features/branch/authentication/presentation/provider/auth_provider.dart';

final syncService = SyncService();
final supabase = Supabase.instance.client;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return ProviderScope(
      child: MaterialApp(
        title: 'Jan Ghani',
        debugShowCheckedModeBanner: false,
        theme: LightTheme.theme,
        home: auth.isLoading ?
        Scaffold(
          body: const CircularProgressIndicator(),
        ) :
        auth.isLoggedIn ?
        const BranchSideBar() :
        const LoginScreen(),
      ),
    );
  }
}





