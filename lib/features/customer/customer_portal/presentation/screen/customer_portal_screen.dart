import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accountant_auth_providers.dart';
import 'package:jan_ghani_final/features/customer/customer_invoices/data/datasource/customer_report_datasource.dart';
import 'package:jan_ghani_final/features/customer/customer_invoices/presentation/widget/customer_avatar.dart';
import 'package:jan_ghani_final/features/customer/customer_invoices/presentation/widget/customer_invoices_tab.dart';

const _bg = Color(0xFFF4F5F0);
const _muted = Color(0xFF5A6660);
const _line = Color(0xFFE2E5DE);

/// Login ke baad customer ka portal (route: /customer/:customerId).
/// Branch ke customer ki invoice history dikhata hai — sirf unke liye jinka
/// `customer_token` hai.
class CustomerPortalScreen extends ConsumerStatefulWidget {
  /// Route ki id (customer_token) — asli id session se aati hai.
  final String customerId;
  const CustomerPortalScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerPortalScreen> createState() =>
      _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends ConsumerState<CustomerPortalScreen> {
  String? _name; // branch `customer` table se

  String? get _token {
    final t = ref.read(currentUserProvider)?.customerToken;
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  void initState() {
    super.initState();
    final t = _token;
    if (t == null) return;
    CustomerReportDatasource().getCustomerInfo(t).then((row) {
      final n = row?['name'] as String?;
      if (mounted && n != null && n.isNotEmpty) setState(() => _name = n);
    }).catchError((_) {});
  }

  void _logout() => ref.read(accountantAuthNotifierProvider.notifier).logout();

  String get _displayName =>
      _name ?? ref.read(currentUserProvider)?.fullName ?? '';

  @override
  Widget build(BuildContext context) {
    ref.watch(currentUserProvider);
    final token = _token;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.manropeTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _InvoicesHeader(
                    avatar: CustomerAvatar(
                      customerId: token ?? widget.customerId,
                      name: _displayName,
                      size: 48,
                      editable: token != null, // photo `customer` row par save hoti hai
                    ),
                    name: _displayName,
                    onLogout: _logout,
                  ),
                  if (token != null)
                    Expanded(child: CustomerInvoicesTab(customerId: token)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvoicesHeader extends StatelessWidget {
  final Widget avatar;
  final String name;
  final VoidCallback onLogout;
  const _InvoicesHeader({
    required this.avatar,
    required this.name,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, color: _muted),
            ),
          ],
        ),
      );
}
