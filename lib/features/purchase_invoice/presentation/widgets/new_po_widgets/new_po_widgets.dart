// =============================================================
// new_po_widgets.dart
// NewPurchaseOrderScreen ke reusable widgets:
//   - NewPoSectionCard   — card wrapper with step number
//   - NewPoFieldLabel    — field label with optional *
//   - NewPoNumField      — number input field
//   - NewPoDateField     — date display field
//   - NewPoSupplierChip  — selected supplier display
//   - NewPoTableHeader   — products table column headers
//   - NewPoProfitCard    — profit summary card
//   - NewPoTotalRow      — totals box row
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

// ─────────────────────────────────────────────────────────────
// SECTION CARD — card with step number + icon + title
// ─────────────────────────────────────────────────────────────

class NewPoSectionCard extends StatelessWidget {
  final String   stepNum;
  final Color    stepColor;
  final IconData icon;
  final String   title;
  final Widget?  trailing;
  final Widget   child;

  const NewPoSectionCard({
    super.key,
    required this.stepNum,
    required this.stepColor,
    required this.icon,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColor.grey200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color:  stepColor.withOpacity(0.1),
                    shape:  BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(stepNum,
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: stepColor)),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color:        stepColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 13, color: stepColor),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child:   child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FIELD LABEL
// ─────────────────────────────────────────────────────────────

class NewPoFieldLabel extends StatelessWidget {
  final String label;
  final bool   required;
  const NewPoFieldLabel(
      {super.key, required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary)),
        if (required)
          Text(' *',
              style:
              TextStyle(fontSize: 12, color: AppColor.error)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NUMBER INPUT FIELD
// ─────────────────────────────────────────────────────────────

class NewPoNumField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final VoidCallback          onChanged;
  final bool                  isPurple;

  const NewPoNumField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.isPurple = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   controller,
      onChanged:    (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(
          decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
      ],
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColor.textPrimary),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: TextStyle(fontSize: 12,
            color: AppColor.textHint),
        filled:    true,
        fillColor: isPurple
            ? AppColor.primary.withOpacity(0.05)
            : AppColor.grey100,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
                color: isPurple
                    ? AppColor.primary : AppColor.grey200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
                color: isPurple
                    ? AppColor.primary : AppColor.grey200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
            BorderSide(color: AppColor.primary, width: 1.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE FIELD
// ─────────────────────────────────────────────────────────────

class NewPoDateField extends StatelessWidget {
  final DateTime? date;
  final String    placeholder;

  const NewPoDateField(
      {super.key, this.date, this.placeholder = 'Select date'});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final txt = date != null
        ? '${date!.day.toString().padLeft(2, '0')} '
        '${months[date!.month - 1]} ${date!.year}'
        : placeholder;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        border:       Border.all(color: AppColor.grey300),
        borderRadius: BorderRadius.circular(8),
        color:        AppColor.grey100,
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 14, color: AppColor.grey400),
          const SizedBox(width: 8),
          Text(txt,
              style: TextStyle(fontSize: 13,
                  color: date != null
                      ? AppColor.textPrimary
                      : AppColor.textHint)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER CHIP — selected supplier display
// ─────────────────────────────────────────────────────────────

class NewPoSupplierChip extends StatelessWidget {
  final String       name;
  final String       company;
  final int          terms;
  final VoidCallback onTap;

  const NewPoSupplierChip({
    super.key,
    required this.name,
    required this.company,
    required this.terms,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2)
        .map((w) => w[0]).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border:       Border.all(color: AppColor.grey300),
        borderRadius: BorderRadius.circular(8),
        color:        AppColor.grey100,
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
                Text('$company  •  $terms days credit',
                    style: TextStyle(fontSize: 11,
                        color: AppColor.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text('Change',
                style: TextStyle(
                    fontSize: 11, color: AppColor.primary)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TABLE HEADER CELL
// ─────────────────────────────────────────────────────────────

class NewPoTableHeaderCell extends StatelessWidget {
  final String label;
  final int    flex;
  final bool   right;
  final bool   center;
  final bool   purple;

  const NewPoTableHeaderCell({
    super.key,
    required this.label,
    this.flex   = 1,
    this.right  = false,
    this.center = false,
    this.purple = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: center
              ? TextAlign.center
              : right
              ? TextAlign.right
              : TextAlign.left,
          style: TextStyle(
            fontSize:      10,
            fontWeight:    FontWeight.w600,
            color:         purple
                ? AppColor.primary : AppColor.textSecondary,
            letterSpacing: 0.3,
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROFIT CARD
// ─────────────────────────────────────────────────────────────

class NewPoProfitCard extends StatelessWidget {
  final String value;
  final String label;
  final Color  bg;
  final Color  fg;

  const NewPoProfitCard({
    super.key,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w600, color: fg)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOTAL ROW
// ─────────────────────────────────────────────────────────────

class NewPoTotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool   isBold;
  final bool   isLast;

  const NewPoTotalRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
            bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize:   isBold ? 14 : 13,
                fontWeight: isBold
                    ? FontWeight.w600 : FontWeight.w400,
                color:      AppColor.textSecondary,
              )),
          Text(value,
              style: TextStyle(
                fontSize:   isBold ? 14 : 13,
                fontWeight: isBold
                    ? FontWeight.w600 : FontWeight.w500,
                color: valueColor ?? AppColor.textPrimary,
              )),
        ],
      ),
    );
  }
}