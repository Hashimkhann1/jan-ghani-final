import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/branch_transaction_provider.dart';

class CashOutDialog extends ConsumerStatefulWidget {
  const CashOutDialog({super.key});

  @override
  ConsumerState<CashOutDialog> createState() => _CashOutDialogState();
}

class _CashOutDialogState extends ConsumerState<CashOutDialog> {
  final _payController = TextEditingController();
  final _formKey       = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => ref.read(branchTransactionProvider.notifier).loadData(),
    );
  }

  @override
  void dispose() {
    _payController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_payController.text.trim()) ?? 0.0;
    await ref.read(branchTransactionProvider.notifier).cashOut(amount);

    if (!mounted) return;

    final state = ref.read(branchTransactionProvider);
    if (state.isSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:          Text('Cash out successfully ho gaya'),
          backgroundColor:  Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchTransactionProvider);

    ref.listen(branchTransactionProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(branchTransactionProvider.notifier).clearError();
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:        Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_upward_rounded,
                          color: Colors.red.shade400, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cash Out',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Branch se amount nikalna',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // ── Total Amount (disabled) ──────────────
                const Text('Branch Total Amount',
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      Colors.grey)),
                const SizedBox(height: 6),
                state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.blue.shade400, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Rs. ${state.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.w800,
                          color:      Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Pay Amount ───────────────────────────
                const Text('Pay Amount *',
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _payController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixText:  'Rs. ',
                    hintText:    '0.00',
                    filled:      true,
                    fillColor:   Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.red, width: 1.5)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount daalo';
                    final amt = double.tryParse(v.trim());
                    if (amt == null || amt <= 0) return 'Valid amount daalo';
                    if (amt > state.totalAmount) {
                      return 'Total amount se zyada nahi ho sakta';
                    }
                    return null;
                  },
                ),

                // ── After amount preview ─────────────────
                if (_payController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:        Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.orange.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Baad mein: Rs. ${(state.totalAmount - (double.tryParse(_payController.text) ?? 0)).toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                              color:      Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Buttons ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: state.isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: state.isSubmitting
                            ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.arrow_upward_rounded, size: 18),
                        label: const Text('Cash Out',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}