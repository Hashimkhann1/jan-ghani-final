import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/accountant_supplier_model.dart';
import '../provider/accountant_supplier_provider.dart';
import 'supplier_detail_screen.dart';

// =============================================================
// Accountant → All Suppliers (read-only)
// Supplier par click → SupplierDetailScreen
// =============================================================
class AccountantAllSupplierScreen extends ConsumerStatefulWidget {
  final String warehouseId;
  const AccountantAllSupplierScreen({super.key, required this.warehouseId});

  @override
  ConsumerState<AccountantAllSupplierScreen> createState() =>
      _AccountantAllSupplierScreenState();
}

class _AccountantAllSupplierScreenState
    extends ConsumerState<AccountantAllSupplierScreen> {
  String _query = '';
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searchOpen = true);

  void _closeSearch() => setState(() {
        _searchOpen = false;
        _searchCtrl.clear();
        _query = '';
      });

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(accSuppliersProvider(widget.warehouseId));

    // ── Summary totals (data aate hi update; loading par 0) ──────────
    final suppliers      = suppliersAsync.value ?? const <AccountantSupplierModel>[];
    final totalSuppliers = suppliers.length;
    final totalDues      = suppliers
        .where((s) => s.hasDue)
        .fold<double>(0, (sum, s) => sum + s.outstandingBalance);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
        // Search open ho to back arrow search band kare (route pop nahi)
        leading: _searchOpen
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _closeSearch,
              )
            : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _searchOpen
              ? TextField(
                  key: const ValueKey('search'),
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  style: const TextStyle(
                      fontSize: 15, color: AppColor.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Supplier dhoondein...',
                    hintStyle: TextStyle(color: AppColor.textMuted),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                )
              : const Text(
                  'Suppliers',
                  key: ValueKey('title'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textDark,
                  ),
                ),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded),
            onPressed: _searchOpen ? _closeSearch : _openSearch,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Summary cards (Total Suppliers + Total Dues) ──
            // Row mein do barabar cards — mobile (IPA/APP) aur website dono par fit.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon:      Icons.people_alt_rounded,
                      iconBg:    const Color(0xFFEEF0FF),
                      iconColor: AppColor.primary,
                      label:     'Total Suppliers',
                      value:     '$totalSuppliers',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon:      Icons.account_balance_wallet_rounded,
                      iconBg:    const Color(0xFFFDECEC),
                      iconColor: AppColor.cashOut,
                      label:     'Total Dues',
                      value:     _fmtRs(totalDues),
                    ),
                  ),
                ],
              ),
            ),

            // (Search ab AppBar mein expandable hai)
            const SizedBox(height: 12),

            // ── List ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () async =>
                    ref.invalidate(accSuppliersProvider(widget.warehouseId)),
                child: suppliersAsync.when(
                  data: (all) {
                    final list = _query.isEmpty
                        ? all
                        : all
                            .where((s) =>
                                s.name.toLowerCase().contains(_query) ||
                                (s.companyName ?? '')
                                    .toLowerCase()
                                    .contains(_query) ||
                                (s.code ?? '').toLowerCase().contains(_query))
                            .toList();

                    if (list.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Koi supplier nahi mila',
                              style: TextStyle(color: AppColor.textMuted),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) =>
                          _SupplierTile(supplier: list[i], index: i + 1),
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 8,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _ShimmerBox(height: 72),
                    ),
                  ),
                  error: (e, _) => ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Suppliers load nahi hue — pull to refresh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supplier Tile ─────────────────────────────────────────────────────────────
class _SupplierTile extends StatelessWidget {
  final AccountantSupplierModel supplier;
  final int index;
  const _SupplierTile({required this.supplier, required this.index});

  String _money(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${neg ? '- ' : ''}Rs. $s';
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountantSupplierDetailScreen(
            supplierId: supplier.id,
            supplierName: supplier.name,
            companyName: supplier.companyName,
            phone: supplier.phone,
            outstandingBalance: supplier.outstandingBalance,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColor.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supplier.companyName?.isNotEmpty == true
                        ? supplier.companyName!
                        : (supplier.code ?? supplier.phone),
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(supplier.outstandingBalance),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: supplier.hasDue
                        ? AppColor.cashOut
                        : (supplier.isClear
                            ? AppColor.textMuted
                            : AppColor.cashIn),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  supplier.isClear
                      ? 'Clear'
                      : (supplier.hasDue ? 'Due' : 'Advance'),
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textMuted),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColor.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Summary Stat Card ─────────────────────────────────────────────────────────
// Mobile + website dono par kaam karta hai (parent Expanded width deta hai).
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconBg;
  final Color    iconColor;
  final String   label;
  final String   value;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColor.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Rs. formatting (thousands separator) — _SupplierTile._money jaisa hi.
String _fmtRs(double v) {
  final neg = v < 0;
  final s = v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${neg ? '- ' : ''}Rs. $s';
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      );
}
