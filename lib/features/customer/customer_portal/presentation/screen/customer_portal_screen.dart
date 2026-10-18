import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accoutant_session_provider.dart';
import 'package:jan_ghani_final/features/accountant/authentication/presentation/providers/accountant_auth_providers.dart';
import 'package:jan_ghani_final/features/customer/customer_invoices/data/datasource/customer_report_datasource.dart';
import 'package:jan_ghani_final/features/customer/customer_invoices/presentation/widget/customer_avatar.dart';
import 'package:jan_ghani_final/features/customer/customer_invoices/presentation/widget/customer_invoices_tab.dart';
import 'package:jan_ghani_final/features/installment/installment_customer_portal/presentation/widget/installment_portal_tabs.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/presentation/provider/installment_dashboard_provider.dart';

const _bg = Color(0xFFF4F5F0);
const _muted = Color(0xFF5A6660);
const _line = Color(0xFFE2E5DE);
const _green = Color(0xFF0F5C3F);

/// Login ke baad customer ka portal (route: /customer/:customerId).
/// Bottom nav: Home / Schedule / History (installment tabs, installment feature
/// se, data database se) aur Invoices (branch ke customer ki invoice history —
/// sirf unke liye jinka `customer_token` hai). installment_id na ho (ya plan na
/// ho) to pehle teen tabs par empty screen dikhti hai.
/// installment_id null ho to sirf Invoices screen dikhti hai (koi bottom nav
/// nahi); installment_id ho to installment tabs bhi dikhte hain.
class CustomerPortalScreen extends ConsumerStatefulWidget {
  /// Route ki id (customer_token ya installment_id) — asli ids session se aati hain.
  final String customerId;
  const CustomerPortalScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerPortalScreen> createState() =>
      _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends ConsumerState<CustomerPortalScreen> {
  int? _tab; // null = pehla available tab (installment ho to Home, warna Invoices)
  int _planIndex = 0;
  String? _name; // branch `customer` table se (sirf customer_token wale)

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

  String _displayName(InstallmentCustomer? c) =>
      c?.name ?? _name ?? ref.read(currentUserProvider)?.fullName ?? '';

  Widget _avatar(InstallmentCustomer? c) {
    final token = _token;
    return CustomerAvatar(
      customerId: token ?? widget.customerId,
      name: _displayName(c),
      size: 48,
      editable: token != null, // photo `customer` row par save hoti hai
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final installmentId = user?.installmentId;
    final hasId = installmentId != null && installmentId.isNotEmpty;
    final async =
        hasId ? ref.watch(installmentCustomerProvider(installmentId)) : null;
    final customer = async?.valueOrNull;
    final loading = async != null && async.isLoading && !async.hasValue;
    // installment_id null ho, ya us id ki koi installment row hi na ho, to
    // installment tabs nahi dikhte (sirf Invoices).
    final hasInstallment = hasId && (loading || customer != null);
    final token = _token;
    final showInvoices = token != null;
    final invoicesTab = 3;
    // Available tabs: installment (0..2) sirf installment_id par, invoices sirf token par.
    final tabs = [
      if (hasInstallment) ...[0, 1, 2],
      if (showInvoices) invoicesTab,
    ];
    final tab = tabs.contains(_tab) ? _tab! : (tabs.isEmpty ? 0 : tabs.first);

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
                  Expanded(
                    child: tab == invoicesTab
                        ? Column(
                            children: [
                              // Sirf invoices wale customer ke liye Home tab nahi,
                              // is liye logout yahin hai.
                              if (!hasInstallment)
                                _InvoicesHeader(
                                  avatar: _avatar(null),
                                  name: _displayName(null),
                                  onLogout: _logout,
                                ),
                              Expanded(
                                  child: CustomerInvoicesTab(customerId: token!)),
                            ],
                          )
                        : loading
                            ? const Center(child: CircularProgressIndicator())
                            : _page(tab, customer),
                  ),
                  if (tabs.length > 1)
                    _PortalBottomNav(
                      index: tab,
                      showInvoices: showInvoices,
                      onTap: (i) => setState(() => _tab = i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _page(int tab, InstallmentCustomer? customer) {
    if (customer == null) {
      return InstallmentEmptyTab(
        tab: tab,
        onLogout: _logout,
        avatar: _avatar(null),
        displayName: _displayName(null),
      );
    }
    final plans = customer.plans;
    if (tab == 0) {
      return InstallmentHomeTab(
        customer: customer,
        onLogout: _logout,
        avatar: _avatar(customer),
        displayName: _displayName(customer),
      );
    }
    if (plans.isEmpty) {
      return InstallmentEmptyTab(tab: tab, onLogout: _logout);
    }
    final plan = plans[_planIndex.clamp(0, plans.length - 1)];
    return InstallmentPlanPicker(
      customer: customer,
      index: _planIndex,
      onPick: (i) => setState(() => _planIndex = i),
      child: tab == 1
          ? InstallmentScheduleTab(plan: plan)
          : InstallmentHistoryTab(customer: customer, plan: plan),
    );
  }
}

class _PortalBottomNav extends StatelessWidget {
  final int index;
  final bool showInvoices;
  final ValueChanged<int> onTap;
  const _PortalBottomNav({
    required this.index,
    required this.showInvoices,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Schedule'),
      (Icons.history_rounded, Icons.history_rounded, 'History'),
      if (showInvoices)
        (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Invoices'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: SizedBox(
                  height: 52,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(i == index ? items[i].$2 : items[i].$1,
                          size: 22, color: i == index ? _green : _muted),
                      const SizedBox(height: 4),
                      Text(items[i].$3,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  i == index ? FontWeight.w700 : FontWeight.w600,
                              color: i == index ? _green : _muted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
