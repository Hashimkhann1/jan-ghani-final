// Updated on 2026-10-08 09:24 AM
// =============================================================
// inventory_balance_screen.dart
// Warehouse-side Inventory Balance shell — 2 tabs:
//   1. Create Balance Request
//   2. Report / History
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

import '../widgets/balance_report_panel.dart';
import '../widgets/create_batch_panel.dart';

class InventoryBalanceScreen extends StatefulWidget {
  const InventoryBalanceScreen({super.key});

  @override
  State<InventoryBalanceScreen> createState() => _InventoryBalanceScreenState();
}

class _InventoryBalanceScreenState extends State<InventoryBalanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top bar (title + segmented tabs on right) ─────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColor.surface,
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.rule_folder_outlined,
                    size: 19, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Inventory Balance',
                      style: TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800,
                        color: AppColor.textPrimary,
                      )),
                  SizedBox(height: 2),
                  Text('Weekly balance requests · owner-only',
                      style: TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                ],
              ),
              const Spacer(),
              // ── Delta calculator (sirf manual hisaab — kuch save nahi) ──
              Tooltip(
                message: 'Delta calculator',
                child: InkWell(
                  onTap: () => _DeltaCalculatorDialog.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color:        AppColor.surface,
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: AppColor.grey300),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.calculate_outlined,
                        size: 20, color: AppColor.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _SegmentedTabs(
                controller: _tabs,
                tabs: const [
                  _TabSpec(label: 'Create Request', icon: Icons.add_circle_outline_rounded),
                  _TabSpec(label: 'History / Report', icon: Icons.history_rounded),
                ],
              ),
            ],
          ),
        ),

        // ── Content ───────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              CreateBatchPanel(),
              BalanceReportPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEGMENTED TABS  (custom pill-style)
// ─────────────────────────────────────────────────────────────
class _TabSpec {
  final String label;
  final IconData icon;
  const _TabSpec({required this.label, required this.icon});
}

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<_TabSpec> tabs;
  const _SegmentedTabs({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (i) {
          final active = controller.index == i;
          return Padding(
            padding: EdgeInsets.only(right: i == tabs.length - 1 ? 0 : 4),
            child: _SegmentButton(
              spec: tabs[i],
              active: active,
              onTap: () => controller.animateTo(i),
            ),
          );
        }),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final _TabSpec spec;
  final bool active;
  final VoidCallback onTap;
  const _SegmentButton({
    required this.spec, required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? AppColor.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active
            ? [BoxShadow(
                color: AppColor.primary.withOpacity(0.25),
                blurRadius: 8, offset: const Offset(0, 2),
              )]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  spec.icon,
                  size: 15,
                  color: active ? Colors.white : AppColor.textSecondary,
                ),
                const SizedBox(width: 7),
                Text(
                  spec.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColor.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DELTA CALCULATOR — System Stock + Counted Stock → Delta
// Delta = Counted − System (Create Request wala hi semantic).
// Sirf calculator hai — koi provider / DB nahi chhoota.
// ─────────────────────────────────────────────────────────────
class _DeltaCalculatorDialog extends StatefulWidget {
  const _DeltaCalculatorDialog();

  static void show(BuildContext context) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => const _DeltaCalculatorDialog(),
    );
  }

  @override
  State<_DeltaCalculatorDialog> createState() => _DeltaCalculatorDialogState();
}

class _DeltaCalculatorDialogState extends State<_DeltaCalculatorDialog> {
  final _systemCtrl  = TextEditingController();
  final _countedCtrl = TextEditingController();

  @override
  void dispose() {
    _systemCtrl.dispose();
    _countedCtrl.dispose();
    super.dispose();
  }

  double? _parse(String t) => double.tryParse(t.trim());

  /// 12 / 12.5 / 12.125 — trailing zeros hata ke
  String _fmt(double v) =>
      v.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');

  void _clear() {
    _systemCtrl.clear();
    _countedCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final system  = _parse(_systemCtrl.text);
    final counted = _parse(_countedCtrl.text);
    final delta   = (system != null && counted != null) ? counted - system : null;
    // Apply ke baad stock = System + Delta
    final after   = delta == null ? null : system! + delta;

    final Color deltaColor = delta == null || delta == 0
        ? AppColor.textSecondary
        : (delta > 0 ? AppColor.success : AppColor.error);
    final String deltaText = delta == null
        ? '—'
        : delta > 0 ? '+${_fmt(delta)}' : (delta < 0 ? '−${_fmt(-delta)}' : '0');
    final String hint = delta == null
        ? 'Dono values daalein'
        : delta > 0
            ? 'Stock barhega (zyada gina gaya)'
            : delta < 0 ? 'Stock kam hoga (kam gina gaya)' : 'Koi farq nahi';

    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color:        AppColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.calculate_outlined,
                        size: 18, color: AppColor.primary),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Delta Calculator',
                        style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textPrimary)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppColor.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _NumField(
                label:      'System Stock',
                controller: _systemCtrl,
                autofocus:  true,
                onChanged:  () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _NumField(
                label:      'Counted Stock',
                controller: _countedCtrl,
                onChanged:  () => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Result
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color:        deltaColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: deltaColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text('DELTA  (Counted − System)',
                        style: TextStyle(
                            fontSize:      11,
                            fontWeight:    FontWeight.w600,
                            letterSpacing: 0.6,
                            color:         AppColor.textSecondary)),
                    const SizedBox(height: 4),
                    Text(deltaText,
                        style: TextStyle(
                            fontSize:   28,
                            fontWeight: FontWeight.w800,
                            color:      deltaColor)),
                    Text(hint,
                        style: TextStyle(fontSize: 12, color: deltaColor)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Apply ke baad stock
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color:        AppColor.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: AppColor.grey200),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('APPLY KE BAAD STOCK',
                              style: TextStyle(
                                  fontSize:      11,
                                  fontWeight:    FontWeight.w600,
                                  letterSpacing: 0.6,
                                  color:         AppColor.textSecondary)),
                          SizedBox(height: 2),
                          Text('System + Delta',
                              style: TextStyle(
                                  fontSize: 11.5, color: AppColor.textHint)),
                        ],
                      ),
                    ),
                    Text(
                      after == null
                          ? '—'
                          : (after < 0 ? '−${_fmt(-after)}' : _fmt(after)),
                      style: TextStyle(
                          fontSize:   22,
                          fontWeight: FontWeight.w800,
                          color: after != null && after < 0
                              ? AppColor.error : AppColor.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.textSecondary,
                        side: const BorderSide(color: AppColor.grey300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: AppColor.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final VoidCallback          onChanged;
  final bool                  autofocus;

  const _NumField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize:      11,
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.5,
                color:         AppColor.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus:  autofocus,
          onChanged:  (_) => onChanged(),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          // Minus (negative system stock) + decimal allowed
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
          ],
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense:   true,
            hintText:  '0',
            filled:    true,
            fillColor: AppColor.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColor.grey300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColor.grey300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
