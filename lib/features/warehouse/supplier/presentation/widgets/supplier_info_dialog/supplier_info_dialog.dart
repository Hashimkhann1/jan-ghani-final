// =============================================================
// supplier_info_dialog.dart
// Supplier name click karne pe khulne wala dialog
// Supplier ki saari basic details dikhata hai
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';

class SupplierInfoDialog extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierInfoDialog({super.key, required this.supplier});

  // ── Static helper — dialog ko easily open karo ────────────
  static void show(BuildContext context, SupplierModel supplier) {
    showDialog(
      context:           context,
      barrierColor:      Colors.black.withOpacity(0.35),
      builder:           (_) => SupplierInfoDialog(supplier: supplier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = supplier;

    return Dialog(
      shape:             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor:   AppColor.surface,
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────
            _DialogHeader(supplier: s,
                onClose: () => Navigator.of(context).pop()),

            // ── Detail rows ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Required fields — hamesha dikhao
                  _InfoRow(
                    icon:  Icons.person_outline_rounded,
                    label: 'Supplier name',
                    value: s.name,
                  ),
                  _InfoRow(
                    icon:  Icons.phone_outlined,
                    label: 'Phone',
                    value: s.phone,
                  ),

                  // Optional fields — sirf tab dikhao jab value ho
                  if (s.contactPerson != null && s.contactPerson != s.name)
                    _InfoRow(
                      icon:  Icons.badge_outlined,
                      label: 'Contact person',
                      value: s.contactPerson!,
                    ),
                  if (s.email != null)
                    _InfoRow(
                      icon:  Icons.email_outlined,
                      label: 'Email',
                      value: s.email!,
                    ),
                  if (s.address != null)
                    _InfoRow(
                      icon:  Icons.location_on_outlined,
                      label: 'Address',
                      value: s.address!,
                    ),
                  if (s.taxId != null)
                    _InfoRow(
                      icon:  Icons.receipt_long_outlined,
                      label: 'Tax ID (NTN)',
                      value: s.taxId!,
                    ),
                  _InfoRow(
                    icon:       Icons.schedule_outlined,
                    label:      'Payment terms',
                    value:      '${s.paymentTerms} days credit',
                    valueColor: AppColor.info,
                  ),
                  if (s.code != null)
                    _InfoRow(
                      icon:       Icons.tag_rounded,
                      label:      'Supplier code',
                      value:      s.code!,
                      valueColor: AppColor.primary,
                    ),
                  if (s.notes != null)
                    _InfoRow(
                      icon:       Icons.notes_rounded,
                      label:      'Notes',
                      value:      s.notes!,
                      isLast:     true,
                    ),

                  // agar notes nahi hai to last row pe border nahi
                  if (s.notes == null)
                    _InfoRow(
                      icon:   Icons.schedule_outlined,
                      label:  'Member since',
                      value:  _formatDate(s.createdAt),
                      isLast: true,
                    ),
                ],
              ),
            ),

            // ── Footer — Edit + Delete ─────────────────────
            _DialogFooter(
              onEdit:   () {
                Navigator.of(context).pop();
                // TODO: Edit dialog open karo
              },
              onDelete: () {
                Navigator.of(context).pop();
                // TODO: Delete confirm dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';
}

// ─────────────────────────────────────────────────────────────
// DIALOG HEADER
// ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback  onClose;

  const _DialogHeader({required this.supplier, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColor.primary),
            ),
          ),
          const SizedBox(width: 12),

          // Name + code + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.name,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Code pill
                    if (supplier.code != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:        AppColor.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(supplier.code!,
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColor.primary)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Active badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: supplier.isActive
                            ? AppColor.successLight : AppColor.grey200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: supplier.isActive
                                  ? AppColor.success : AppColor.grey400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            supplier.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize:   10,
                              fontWeight: FontWeight.w600,
                              color: supplier.isActive
                                  ? AppColor.success : AppColor.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close button
          InkWell(
            onTap:        onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:        AppColor.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close_rounded, size: 16,
                  color: AppColor.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INFO ROW  — har detail ke liye ek row
// ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final bool     isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color:        AppColor.grey100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: AppColor.grey500),
          ),
          const SizedBox(width: 12),

          // Label
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
          ),

          // Value
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                  color:      valueColor ?? AppColor.textPrimary,
                ),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG FOOTER  — Edit + Delete
// ─────────────────────────────────────────────────────────────

class _DialogFooter extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DialogFooter({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Edit button
          InkWell(
            onTap:        onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColor.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 14, color: AppColor.primary),
                  const SizedBox(width: 6),
                  Text('Edit supplier',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: AppColor.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          InkWell(
            onTap:        onDelete,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:        AppColor.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 14,
                      color: AppColor.error),
                  const SizedBox(width: 6),
                  Text('Delete',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: AppColor.error)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}