import 'package:flutter/material.dart';
import '../../data/model/dashboard_model.dart';

// ─── Top 10 Products ──────────────────────────────────────────────────────
class TopProductsList extends StatelessWidget {
  final List<TopProduct> products;
  const TopProductsList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return _ListPanel(
      title: 'Top 10 Products',
      icon: Icons.inventory_2_outlined,
      headers: const ['#', 'Product', 'Qty', 'Amount'],
      rows: products.map((p) => _RowData(
        rank: p.rank,
        name: p.name,
        secondary: '${p.qty} pcs',
        amount: p.amount,
      )).toList(),
    );
  }
}

// ─── Top 10 Customers ─────────────────────────────────────────────────────
class TopCustomersList extends StatelessWidget {
  final List<TopCustomer> customers;
  const TopCustomersList({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    return _ListPanel(
      title: 'Top 10 Customers',
      icon: Icons.people_outline_rounded,
      headers: const ['#', 'Customer', 'Orders', 'Amount'],
      rows: customers.map((c) => _RowData(
        rank: c.rank,
        name: c.name,
        secondary: '${c.orders} orders',
        amount: c.amount,
      )).toList(),
    );
  }
}

// ─── Shared list panel ────────────────────────────────────────────────────
class _RowData {
  final int rank;
  final String name;
  final String secondary;
  final double amount;
  const _RowData({
    required this.rank,
    required this.name,
    required this.secondary,
    required this.amount,
  });
}

class _ListPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> headers;
  final List<_RowData> rows;

  const _ListPanel({
    required this.title,
    required this.icon,
    required this.headers,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D23),
                  ),
                ),
              ],
            ),
          ),
          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    headers[0],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    headers[1],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    headers[2],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    headers[3],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return _ListRow(data: r, isEven: i.isEven);
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final _RowData data;
  final bool isEven;
  const _ListRow({required this.data, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final amtStr = _fmt(data.amount);
    final rankColor = data.rank <= 3
        ? [
      const Color(0xFFF59E0B),
      const Color(0xFF9CA3AF),
      const Color(0xFFCD7C2F),
    ][data.rank - 1]
        : const Color(0xFFD1D5DB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: isEven ? Colors.white : const Color(0xFFFAFAFB),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${data.rank}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              data.name,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Secondary (qty / orders)
          SizedBox(
            width: 60,
            child: Text(
              data.secondary,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          // Amount
          SizedBox(
            width: 80,
            child: Text(
              amtStr,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1D23),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return 'Rs ${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(1)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}