import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/service/session/accountant_session.dart';
import '../../../accountant_all_warehouses/data/model/accountant_warehouse_model.dart';
import '../../../accountant_all_warehouses/presentation/provider/accountant_warehouse_provider.dart';
import '../../../accountant_cash_transfer/presentation/provider/cash_transfer_provider.dart';
import '../../../accountant_cash_transfer/presentation/screen/cash_transfers_screen.dart';
import '../provider/janghani_net_amount_provider.dart';

// =============================================================
// Send Cash Dialog (UI only — implement baad mein)
// • janghani_net_amount ka cash_in_hand show karta hai
// • Warehouse dropdown (default: "Select warehouse")
// • Amount text field (sirf numbers, > 0, <= cash_in_hand)
// • Validation warnings + Send Cash button
// =============================================================
class SendCashDialog extends ConsumerStatefulWidget {
  const SendCashDialog({super.key});

  @override
  ConsumerState<SendCashDialog> createState() => _SendCashDialogState();
}

class _SendCashDialogState extends ConsumerState<SendCashDialog> {
  AccountantWarehouseModel? _selectedWarehouse;
  final _amountCtrl = TextEditingController();
  String? _amountError;
  String? _warehouseError;
  bool _sending = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  // Amount validate karo (cash in hand ke against)
  void _validateAmount(double cashInHand) {
    final text = _amountCtrl.text.trim();
    setState(() {
      if (text.isEmpty) {
        _amountError = null;
      } else {
        final amount = double.tryParse(text);
        if (amount == null || amount <= 0) {
          _amountError = 'Amount 0 se zyada hona chahiye';
        } else if (amount > cashInHand) {
          _amountError =
              'Amount cash in hand (${_money(cashInHand)}) se zyada nahi ho sakta';
        } else {
          _amountError = null;
        }
      }
    });
  }

  Future<void> _onSendPressed(double cashInHand) async {
    final text = _amountCtrl.text.trim();
    final amount = double.tryParse(text);

    setState(() {
      _warehouseError =
          _selectedWarehouse == null ? 'Warehouse select karein' : null;

      if (text.isEmpty) {
        _amountError = 'Amount enter karein';
      } else if (amount == null || amount <= 0) {
        _amountError = 'Amount 0 se zyada hona chahiye';
      } else if (amount > cashInHand) {
        _amountError =
            'Amount cash in hand (${_money(cashInHand)}) se zyada nahi ho sakta';
      } else {
        _amountError = null;
      }
    });

    if (_warehouseError != null || _amountError != null) return;

    setState(() => _sending = true);
    try {
      final session = await AccountantSession.getAll();
      await ref.read(cashTransferRepositoryProvider).sendCash(
            warehouseId: _selectedWarehouse!.id,
            warehouseName: _selectedWarehouse!.name,
            amount: amount!,
            sentById: session?['id'] as String?,
            sentByName: (session?['name'] as String?) ?? 'Accountant',
          );

      // List refresh
      ref.invalidate(myCashTransfersProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cash request bheji gayi — ${_money(amount)} → '
            '${_selectedWarehouse!.name} (Pending)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cash bhejne mein masla — dobara koshish karein')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashAsync = ref.watch(janghaniCashInHandProvider);
    final warehousesAsync = ref.watch(accAllWarehousesProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: AppColor.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Send Cash',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountantCashTransfersScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.history_rounded,
                      color: AppColor.textMuted, size: 22),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: AppColor.textMuted, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Cash in Hand display ───────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Cash in Hand',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  cashAsync.when(
                    data: (cash) => Text(
                      _money(cash),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    error: (_, __) => const Text(
                      'Load nahi hua',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Warehouse dropdown ─────────────────────────────
            const Text(
              'Warehouse',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColor.textDark,
              ),
            ),
            const SizedBox(height: 6),
            warehousesAsync.when(
              data: (warehouses) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColor.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _warehouseError != null
                        ? AppColor.cashOut
                        : Colors.transparent,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AccountantWarehouseModel>(
                    value: _selectedWarehouse,
                    isExpanded: true,
                    hint: const Text(
                      'Select warehouse',
                      style:
                          TextStyle(color: AppColor.textMuted, fontSize: 14),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColor.textMuted),
                    items: warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w,
                            child: Text(
                              w.name,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColor.textDark),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (w) => setState(() {
                      _selectedWarehouse = w;
                      _warehouseError = null;
                    }),
                  ),
                ),
              ),
              loading: () => const SizedBox(
                height: 50,
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColor.primary),
                  ),
                ),
              ),
              error: (_, __) => const Text(
                'Warehouses load nahi hue',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            if (_warehouseError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _warehouseError!,
                  style: const TextStyle(color: AppColor.cashOut, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),

            // ── Amount field ───────────────────────────────────
            const Text(
              'Amount to Send',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColor.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Sirf numbers + ek decimal point
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (_) {
                final cash = cashAsync.asData?.value ?? 0;
                _validateAmount(cash);
              },
              decoration: InputDecoration(
                hintText: 'Enter Amount to send',
                hintStyle:
                    const TextStyle(color: AppColor.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.payments_rounded,
                    color: AppColor.textMuted, size: 20),
                filled: true,
                fillColor: AppColor.grey100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _amountError != null
                        ? AppColor.cashOut
                        : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _amountError != null
                        ? AppColor.cashOut
                        : AppColor.primary,
                  ),
                ),
              ),
            ),
            if (_amountError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColor.cashOut, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _amountError!,
                        style: const TextStyle(
                            color: AppColor.cashOut, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),

            // ── Send Cash button ───────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending
                    ? null
                    : () => _onSendPressed(cashAsync.asData?.value ?? 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColor.primary.withOpacity(0.5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Send Cash',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
