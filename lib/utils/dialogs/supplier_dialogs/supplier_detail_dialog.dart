import 'package:flutter/material.dart';
import 'package:jan_ghani_final/model/supplier_model/supplier_model.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHOW HELPER
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showSupplierDetailDialog(
    BuildContext context, SupplierModel supplier) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => SupplierDetailDialog(supplier: supplier),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class SupplierDetailDialog extends StatelessWidget {
  final SupplierModel supplier;

  const SupplierDetailDialog({super.key, required this.supplier});

  static const _divider = Color(0xFFE9ECEF);
  static const _subText = Color(0xFF6C757D);
  static const _sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF9E9E9E),
    letterSpacing: 1.1,
  );
  static const _valueText = TextStyle(
    fontSize: 14,
    color: Color(0xFF212529),
  );

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 60),
      child: SizedBox(
        width: 580,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    const Divider(color: _divider, height: 1),
                    const SizedBox(height: 20),
                    _buildContactSection(),
                    const SizedBox(height: 20),
                    const Divider(color: _divider, height: 1),
                    const SizedBox(height: 20),
                    _buildBusinessDetails(),
                    const SizedBox(height: 20),
                    const Divider(color: _divider, height: 1),
                    const SizedBox(height: 16),
                    _buildFooterDates(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.primaryColors,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Name + contact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  supplier.contact,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _subText,
                  ),
                ),
              ],
            ),
          ),
          // Edit button + close
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF212529),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: _subText),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        _ActionBtn(
          icon: Icons.email_outlined,
          label: 'Email',
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.phone_outlined,
          label: 'Call',
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.menu_book_outlined,
          label: 'Ledger',
          onTap: () {},
        ),
      ],
    );
  }

  // ── Contact Section ───────────────────────────────────────────────────────
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CONTACT', style: _sectionLabel),
        const SizedBox(height: 14),
        _ContactRow(
          icon: Icons.email_outlined,
          value: supplier.email,
        ),
        const SizedBox(height: 12),
        _ContactRow(
          icon: Icons.phone_outlined,
          value: supplier.phone,
        ),
        const SizedBox(height: 12),
        _ContactRow(
          icon: Icons.location_on_outlined,
          value: supplier.address,
        ),
      ],
    );
  }

  // ── Business Details ──────────────────────────────────────────────────────
  Widget _buildBusinessDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BUSINESS DETAILS', style: _sectionLabel),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _BusinessField(
                label: 'Payment Terms',
                icon: Icons.credit_card_outlined,
                value: supplier.paymentTerms,
              ),
            ),
            Expanded(
              child: _BusinessField(
                label: 'Lead Time',
                icon: Icons.access_time_outlined,
                value: supplier.leadTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _BusinessField(
                label: 'Tax ID',
                icon: Icons.description_outlined,
                value: supplier.taxId,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rating',
                      style: TextStyle(
                          fontSize: 13,
                          color: _subText)),
                  const SizedBox(height: 6),
                  supplier.rating != null
                      ? Row(
                    children: [
                      ...List.generate(5, (i) {
                        return Icon(
                          i < supplier.rating!.floor()
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: const Color(0xFFF59E0B),
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        supplier.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212529)),
                      ),
                    ],
                  )
                      : const Text(
                    'Not rated',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF212529)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Footer Dates ─────────────────────────────────────────────────────────
  Widget _buildFooterDates() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: _subText),
            const SizedBox(width: 6),
            Text(
              'Added ${_formatDate(supplier.addedDate ?? DateTime.now())}',
              style: const TextStyle(fontSize: 12, color: _subText),
            ),
          ],
        ),
        Text(
          'Updated ${_formatDate(supplier.updatedDate ?? DateTime.now())}',
          style: const TextStyle(fontSize: 12, color: _subText),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF212529),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle:
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6C757D)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF212529))),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUSINESS FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;

  const _BusinessField({
    required this.label,
    required this.icon,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6C757D))),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
            const SizedBox(width: 8),
            Text(
              value ?? '—',
              style: TextStyle(
                fontSize: 14,
                color: value != null
                    ? const Color(0xFF212529)
                    : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}