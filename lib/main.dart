import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/core/theme/light_theme.dart';
import 'package:jan_ghani_final/features/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/auth/presentation/screens/login_screen.dart';
import 'core/widget/sidebar/sidebar_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Config load karo
  await AppConfig.load();

  // DB connect karo
  await DatabaseService.getConnection();

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
      title:                    'Jan Ghani Warehouse',
      debugShowCheckedModeBanner: false,
      theme:                    LightTheme.theme,
      home:                     const _AuthWrapper(),
    );
  }
}

// ── Auth Wrapper ──────────────────────────────────────────────
// Login check karo — agar logged in hai toh SideBar
// agar nahi toh LoginScreen
class _AuthWrapper extends ConsumerWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Loading — app start pe SharedPreferences check ho raha hai
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