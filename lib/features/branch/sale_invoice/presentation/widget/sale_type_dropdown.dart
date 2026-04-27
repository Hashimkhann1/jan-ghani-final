// lib/features/branch/sale_invoice/presentation/widget/sale_type_dropdown.dart
// ── Up/Down arrow key support added ──

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';

// FocusNode provider ke liye — sale_invoice_screen se access karo
// Tab/Shift+Tab bhi kaam karega

class SaleTypeDropdown extends StatefulWidget {
  final SaleType                value;
  final ValueChanged<SaleType?> onChanged;
  final FocusNode?              focusNode; // shortcut ke liye optional

  const SaleTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.focusNode,
  });

  @override
  State<SaleTypeDropdown> createState() => _SaleTypeDropdownState();
}

class _SaleTypeDropdownState extends State<SaleTypeDropdown> {
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode(debugLabel: 'SaleType');
  }

  @override
  void dispose() {
    // Only dispose if we created it (not passed from outside)
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _cycle(bool forward) {
    final types = SaleType.values;
    final idx   = types.indexOf(widget.value);
    final next  = forward
        ? types[(idx + 1) % types.length]
        : types[(idx - 1 + types.length) % types.length];
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isReturn = widget.value == SaleType.saleReturn;
    final accent   = isReturn ? AppColor.error : AppColor.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with shortcut hint
        Row(children: [
          const Text('Type',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColor.textSecondary)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('↑↓',
                style: TextStyle(
                    fontSize: 8, color: AppColor.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),

        // KeyboardListener wraps the dropdown
        KeyboardListener(
          focusNode:  _focus,
          onKeyEvent: (e) {
            if (e is! KeyDownEvent) return;
            if (e.logicalKey == LogicalKeyboardKey.arrowDown ||
                e.logicalKey == LogicalKeyboardKey.arrowRight) {
              _cycle(true);
            } else if (e.logicalKey == LogicalKeyboardKey.arrowUp ||
                e.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _cycle(false);
            }
          },
          child: Focus(
            onFocusChange: (_) => setState(() {}),
            child: GestureDetector(
              // Tap → toggle
              onTap: () {
                _focus.requestFocus();
                _cycle(true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isReturn
                      ? AppColor.errorLight.withOpacity(0.2)
                      : AppColor.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _focus.hasFocus
                        ? accent
                        : accent.withOpacity(0.6),
                    width: _focus.hasFocus ? 1.8 : 1.2,
                  ),
                ),
                child: Row(children: [
                  Icon(
                    isReturn
                        ? Icons.assignment_return_outlined
                        : Icons.point_of_sale_outlined,
                    size:  15,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.value.label,
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      accent),
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded,
                      size: 14, color: accent.withOpacity(0.6)),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}