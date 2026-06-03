import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/accountant_customer_model.dart';
import '../provider/accountant_customer_provider.dart';

class AccountantCustomerReportScreen extends ConsumerStatefulWidget {
  const AccountantCustomerReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantCustomerReportScreen> createState() =>
      _AccountantCustomerReportScreenState();
}

class _AccountantCustomerReportScreenState
    extends ConsumerState<AccountantCustomerReportScreen> {
  final _searchCtrl = TextEditingController();
  final _amtFmt     = NumberFormat('#,##,###', 'en_IN');

  String _fmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';
  String get _branchId => widget.branchId;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(accountantCustomerReportProvider(_branchId));
    final notifier = ref.read(accountantCustomerReportProvider(_branchId).notifier);

    ref.listen<AccountantCustomerReportState>(
      accountantCustomerReportProvider(_branchId),
          (_, next) {
        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'OK', textColor: Colors.white,
              onPressed: notifier.clearError,
            ),
          ));
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Customer Report',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23))),
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded, color: AppColor.textSecondary),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(children: [

        // ── Search + Filter ───────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(children: [

            // Search
            TextField(
              controller: _searchCtrl,
              onChanged:  notifier.search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Name, phone ya code se search karein...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColor.primary),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColor.textHint),
                  onPressed: () { _searchCtrl.clear(); notifier.search(''); },
                )
                    : null,
                filled: true, fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColor.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Filter chips — All / Credit / Petrol / ⚠️ Exceeded
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'All',      selected: state.filterType == null,        color: AppColor.primary,           onTap: () => notifier.setFilter(null)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Credit',   selected: state.filterType == 'credit',    color: const Color(0xFFF59E0B),    onTap: () => notifier.setFilter('credit')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Petrol',   selected: state.filterType == 'petrol',    color: const Color(0xFF8B5CF6),    onTap: () => notifier.setFilter('petrol')),
                  const SizedBox(width: 8),
                  // Exceeded chip — count badge ke saath
                  _ExceededChip(
                    selected: state.filterType == 'exceeded',
                    count:    state.summary.limitExceededCount,
                    onTap:    () => notifier.setFilter('exceeded'),
                  ),
                ],
              ),
            ),
          ]),
        ),

        // ── Summary Cards ─────────────────────────────────
        Container(
          color:   Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            _SummaryTile(label: 'Total',       value: '${state.summary.totalCustomers}',         icon: Icons.people_outline_rounded,          color: AppColor.primary),
            _vDivider(),
            _SummaryTile(label: 'Active',      value: '${state.summary.activeCustomers}',        icon: Icons.person_outline_rounded,          color: AppColor.success),
            _vDivider(),
            _SummaryTile(label: 'Outstanding', value: _fmt(state.summary.totalOutstanding),      icon: Icons.account_balance_wallet_outlined, color: AppColor.error,           small: true),
            _vDivider(),
            _SummaryTile(label: 'Limit Cross', value: '${state.summary.limitExceededCount}',     icon: Icons.warning_amber_rounded,           color: const Color(0xFFEF4444), small: false),
          ]),
        ),

        Container(height: 1, color: const Color(0xFFE5E7EB)),

        if (!state.isLoading && state.filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Text('${state.filtered.length} customer',
                  style: const TextStyle(fontSize: 12, color: AppColor.textHint)),
            ]),
          )
        else
          const SizedBox(height: 8),

        // ── List ──────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.filtered.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: state.filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _CustomerCard(
                customer: state.filtered[i],
                fmtAmt:   _fmt,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 40, color: const Color(0xFFE5E7EB),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ═══════════════════════════════════════════════════════════
//  Customer Card
// ═══════════════════════════════════════════════════════════

class _CustomerCard extends StatelessWidget {
  final AccountantCustomerReportModel customer;
  final String Function(double) fmtAmt;
  const _CustomerCard({required this.customer, required this.fmtAmt});

  Color get _typeColor {
    switch (customer.customerType) {
      case 'credit': return const Color(0xFFF59E0B);
      case 'petrol': return const Color(0xFF8B5CF6);
      default:       return AppColor.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exceeded     = customer.isCreditLimitExceeded;
    final hasBalance   = customer.balance > 0;
    final balanceColor = exceeded
        ? const Color(0xFFEF4444)       // limit cross — red
        : hasBalance
        ? AppColor.error
        : AppColor.success;
    final usageRatio   = customer.creditUsageRatio;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Limit cross card ko subtle red border
        border: exceeded
            ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.4), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color:      exceeded
                ? const Color(0xFFEF4444).withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top Row ──────────────────────────────────
            Row(children: [

              // Avatar
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _typeColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + Balance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(children: [
                            Flexible(
                              child: Text(customer.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            // Limit cross badge
                            if (exceeded) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.warning_amber_rounded, size: 10, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text('LIMIT CROSS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                                ]),
                              ),
                            ],
                          ]),
                        ),
                        const SizedBox(width: 8),
                        // Balance badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: balanceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: balanceColor.withOpacity(0.3)),
                          ),
                          child: Text(fmtAmt(customer.balance),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: balanceColor)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Phone + Code
                    Row(children: [
                      const Icon(Icons.phone_outlined, size: 12, color: AppColor.textHint),
                      const SizedBox(width: 4),
                      Text(customer.phone.isEmpty ? '-' : customer.phone,
                          style: const TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.tag_rounded, size: 12, color: AppColor.textHint),
                      const SizedBox(width: 2),
                      Text(customer.code, style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
                    ]),
                  ],
                ),
              ),
            ]),

            // ── Credit Limit Section ──────────────────────
            // Sirf tab dikhao jab creditLimit > 0 ho
            if (customer.creditLimit > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: exceeded
                      ? const Color(0xFFEF4444).withOpacity(0.05)
                      : const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label + amounts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(
                            exceeded ? Icons.warning_amber_rounded : Icons.credit_score_outlined,
                            size: 13,
                            color: exceeded ? const Color(0xFFEF4444) : AppColor.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Credit Limit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: exceeded ? const Color(0xFFEF4444) : AppColor.textHint,
                            ),
                          ),
                        ]),
                        // Used / Limit
                        RichText(text: TextSpan(children: [
                          TextSpan(
                            text: fmtAmt(customer.balance),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: exceeded ? const Color(0xFFEF4444) : AppColor.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${fmtAmt(customer.creditLimit)}',
                            style: const TextStyle(fontSize: 11, color: AppColor.textHint),
                          ),
                        ])),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: usageRatio.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: exceeded
                            ? const Color(0xFFEF4444).withOpacity(0.15)
                            : const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          exceeded
                              ? const Color(0xFFEF4444)
                              : usageRatio > 0.75
                              ? const Color(0xFFF59E0B)
                              : AppColor.success,
                        ),
                      ),
                    ),
                    if (exceeded) ...[
                      const SizedBox(height: 5),
                      Text(
                        '⚠️ Limit se ${fmtAmt(customer.balance - customer.creditLimit)} zyada hai',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(usageRatio * 100).toStringAsFixed(0)}% used',
                        style: TextStyle(
                          fontSize: 10,
                          color: usageRatio > 0.75 ? const Color(0xFFF59E0B) : AppColor.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Bottom Row: Address + Type ────────────────
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColor.textHint),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        customer.address.isEmpty ? 'No address' : customer.address,
                        style: const TextStyle(fontSize: 11, color: AppColor.textHint),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _typeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    customer.customerType.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _typeColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Shared Widgets
// ═══════════════════════════════════════════════════════════

class _SummaryTile extends StatelessWidget {
  final String label, value; final IconData icon; final Color color; final bool small;
  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(fontSize: small ? 11 : 13, fontWeight: FontWeight.w800, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final Color color; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? color : AppColor.grey200, width: 1.5),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColor.textSecondary)),
    ),
  );
}

// Exceeded chip — red color + count badge
class _ExceededChip extends StatelessWidget {
  final bool selected; final int count; final VoidCallback onTap;
  const _ExceededChip({required this.selected, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? red : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? red : AppColor.grey200, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.warning_amber_rounded, size: 13,
              color: selected ? Colors.white : red),
          const SizedBox(width: 4),
          Text('Limit Cross',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : red)),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.3) : red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : red)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('Koi customer nahi mila',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      const SizedBox(height: 6),
      Text('Search change karein ya filter hatayein',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
    ]),
  );
}