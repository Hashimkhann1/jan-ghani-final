// =============================================================
// product_audit_dialog.dart
// Product ki change history dikhao
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/warehouse_stock_inventory/data/datasource/product_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class ProductAuditDialog extends StatefulWidget {
  final ProductModel product;
  const ProductAuditDialog({super.key, required this.product});

  static void show(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => ProductAuditDialog(product: product),
    );
  }

  @override
  State<ProductAuditDialog> createState() => _ProductAuditDialogState();
}

class _ProductAuditDialogState extends State<ProductAuditDialog> {
  final _ds = ProductRemoteDataSource();
  late Future<List<ProductAuditLog>> _future;

  @override
  void initState() {
    super.initState();
    _future = _ds.getAuditLog(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Change History',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D23))),
                        Text(widget.product.name,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C7280))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF6C7280)),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Content ───────────────────────────────────
            Expanded(
              child: FutureBuilder<List<ProductAuditLog>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: Color(0xFFEF4444))),
                    );
                  }
                  final logs = snap.data ?? [];
                  if (logs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_toggle_off_rounded,
                              size: 48, color: Color(0xFFD1D5DB)),
                          SizedBox(height: 12),
                          Text('Koi history nahi mili',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6C7280))),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _AuditLogItem(log: logs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single Log Item ───────────────────────────────────────────
class _AuditLogItem extends StatefulWidget {
  final ProductAuditLog log;
  const _AuditLogItem({required this.log});

  @override
  State<_AuditLogItem> createState() => _AuditLogItemState();
}

class _AuditLogItemState extends State<_AuditLogItem> {
  bool _expanded = false;

  Color get _typeColor {
    switch (widget.log.changeType) {
      case 'create': return const Color(0xFF10B981);
      case 'update': return const Color(0xFF6366F1);
      case 'delete': return const Color(0xFFEF4444);
      default:       return const Color(0xFF6C7280);
    }
  }

  IconData get _typeIcon {
    switch (widget.log.changeType) {
      case 'create': return Icons.add_circle_outline_rounded;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline_rounded;
      default:       return Icons.info_outline_rounded;
    }
  }

  String get _typeLabel {
    switch (widget.log.changeType) {
      case 'create': return 'Product Add Kiya';
      case 'update': return 'Product Update Kiya';
      case 'delete': return 'Product Delete Kiya';
      default:       return widget.log.changeType;
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    // UTC → Pakistan Standard Time (UTC+5)
    final pst = dt.toLocal();
    final h = pst.hour > 12 ? pst.hour - 12 : pst.hour == 0 ? 12 : pst.hour;
    final m = pst.minute.toString().padLeft(2, '0');
    final ampm = pst.hour >= 12 ? 'PM' : 'AM';
    return '${pst.day} ${months[pst.month - 1]} ${pst.year}  $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final changes = log.changedFields;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // ── Main row ──────────────────────────────────
          InkWell(
            onTap: changes.isNotEmpty
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_typeIcon, color: _typeColor, size: 16),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_typeLabel,
                            style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w600,
                                color:      _typeColor)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(log.userName,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C7280))),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(_formatDate(log.changedAt),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C7280))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Changed fields count
                  if (changes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${changes.length} changes',
                          style: const TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              color:      Color(0xFF6366F1))),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18, color: const Color(0xFF9CA3AF),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Expanded changes ──────────────────────────
          if (_expanded && changes.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Changes:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C7280),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  ...changes.map((field) => _ChangeRow(
                    field:    field,
                    oldValue: log.oldData?[field]?.toString() ?? '—',
                    newValue: log.newData?[field]?.toString() ?? '—',
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Change Row — old vs new ───────────────────────────────────
class _ChangeRow extends StatelessWidget {
  final String field, oldValue, newValue;
  const _ChangeRow({required this.field, required this.oldValue, required this.newValue});

  String get _label {
    const labels = {
      'name': 'Name', 'sku': 'SKU', 'barcode': 'Barcode',
      'category': 'Category', 'unit': 'Unit',
      'cost_price': 'Cost Price', 'selling_price': 'Sale Price',
      'wholesale_price': 'Wholesale', 'tax_rate': 'Tax %',
      'min_stock': 'Min Stock', 'max_stock': 'Max Stock',
      'reorder_point': 'Reorder Point', 'is_active': 'Status',
      'is_track_stock': 'Track Stock', 'quantity': 'Stock Qty',
    };
    return labels[field] ?? field;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(_label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
          ),
          // Old value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(oldValue,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFEF4444),
                    decoration: TextDecoration.lineThrough)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded,
                size: 12, color: Color(0xFF9CA3AF)),
          ),
          // New value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(newValue,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}