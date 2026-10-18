import 'package:flutter/material.dart';
import '../widget/accountant_login_form.dart';
import '../widget/auth_widgets.dart';

/// Login success par session set hota hai → router (accountant_router.dart)
/// khud dashboard / pichle URL par le jata hai.
class AccountantLoginScreen extends StatelessWidget {
  const AccountantLoginScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AuthShell(child: AccountantLoginForm());
}
