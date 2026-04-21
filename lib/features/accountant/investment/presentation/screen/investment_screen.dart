import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/investment_model.dart';
import '../provider/investment_provider.dart';

class AccountantInvestmentScreen extends ConsumerWidget {
  const AccountantInvestmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investments',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textDark,
                      ),
                    ),
                    Text(
                      'Track your investments',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.textMuted,
                      ),
                    ),
                  ],
                ),

                // ✅ SizedBox mein wrap karo
                SizedBox(
                  width: 100,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddSheet(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Total Card ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: investmentsAsync.when(
              data: (list) {
                final total =
                list.fold<double>(0, (sum, inv) => sum + inv.amount);
                return _TotalCard(total: total, count: list.length);
              },
              loading: () => _ShimmerCard(height: 160),
              error: (_, __) => const _ErrorCard(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Records title ────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Investment Records',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColor.textDark,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: investmentsAsync.when(
              data: (list) => list.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 48,
                      color: AppColor.textMuted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Koi investment nahi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add button se naya investment karo',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.textMuted,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(investmentsProvider),
                child: ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      _InvestmentCard(inv: list[i]),
                ),
              ),
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShimmerCard(height: 80),
                ),
              ),
              error: (e, _) => const Center(child: _ErrorCard()),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddInvestmentSheet(ref: ref),
    );
  }
}

// ── Total Card ────────────────────────────────────────────────────────────────
class _TotalCard extends StatelessWidget {
  final double total;
  final int count;
  const _TotalCard({required this.total, required this.count});

  String _fmt(double val) => 'Rs. ${val.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  )}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Investment',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count active investments',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Investment Card ───────────────────────────────────────────────────────────
class _InvestmentCard extends StatelessWidget {
  final InvestmentModel inv;
  const _InvestmentCard({required this.inv});

  String _fmt(double val) => 'Rs. ${val.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  )}';

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppColor.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Name + Note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColor.textDark,
                  ),
                ),
                if (inv.note != null && inv.note!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    inv.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColor.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Amount + Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(inv.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: AppColor.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _fmtDate(inv.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColor.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add Investment Bottom Sheet ────────────────────────────────────────────────
class _AddInvestmentSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddInvestmentSheet({required this.ref});

  @override
  State<_AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends State<_AddInvestmentSheet> {
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  bool _loading     = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name   = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());

    if (name.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Name aur valid amount zaroor bharo');
      return;
    }

    setState(() {
      _loading = true;
      _error   = null;
    });

    final success = await widget.ref
        .read(addInvestmentProvider.notifier)
        .add(
      name:   name,
      amount: amount,
      note:   _noteCtrl.text.trim().isEmpty
          ? null
          : _noteCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _loading = false;
        _error   = 'Kuch ghalat ho gaya. Dobara koshish karo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'New Investment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColor.textDark,
            ),
          ),
          const SizedBox(height: 20),

          // Name
          _Field(
            controller: _nameCtrl,
            hint: 'Investment name (e.g. Stock Market)',
            icon: Icons.label_rounded,
          ),
          const SizedBox(height: 12),

          // Amount
          _Field(
            controller: _amountCtrl,
            hint: 'Amount (Rs.)',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          // Note
          _Field(
            controller: _noteCtrl,
            hint: 'Note (optional)',
            icon: Icons.notes_rounded,
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Text(
                'Add Investment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Text Field ────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        const TextStyle(color: AppColor.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColor.textMuted, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Shimmer Card ──────────────────────────────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

// ── Error Card ────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Data load nahi hua — pull to refresh karein',
            style: TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}