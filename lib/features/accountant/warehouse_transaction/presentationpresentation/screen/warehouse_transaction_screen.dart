import 'package:flutter/material.dart';

import '../../../../../core/color/app_color.dart';

class AccountantWarehouseTransactionScreen extends StatefulWidget {
  const AccountantWarehouseTransactionScreen({super.key});

  @override
  State<AccountantWarehouseTransactionScreen> createState() =>
      _AccountantWarehouseTransactionScreenState();
}

class _AccountantWarehouseTransactionScreenState extends State<AccountantWarehouseTransactionScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  final List<Map<String, String>> _allTransactions = [
    {
      'warehouse': 'Main Warehouse',
      'user': 'Bilal Khan',
      'amount': 'Rs. 8,500',
      'date': '2024-01-15',
    },
    {
      'warehouse': 'North Storage',
      'user': 'Tariq Nawaz',
      'amount': 'Rs. 22,000',
      'date': '2024-01-14',
    },
    {
      'warehouse': 'South Depot',
      'user': 'Imran Ali',
      'amount': 'Rs. 14,300',
      'date': '2024-01-13',
    },
    {
      'warehouse': 'East Hub',
      'user': 'Kamran Baig',
      'amount': 'Rs. 9,700',
      'date': '2024-01-12',
    },
    {
      'warehouse': 'West Facility',
      'user': 'Asad Mehmood',
      'amount': 'Rs. 31,200',
      'date': '2024-01-11',
    },
  ];

  List<Map<String, String>> get _filtered {
    return _allTransactions.where((t) {
      final d = DateTime.parse(t['date']!);
      if (_startDate != null && d.isBefore(_startDate!)) return false;
      if (_endDate != null && d.isAfter(_endDate!)) return false;
      return true;
    }).toList();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Warehouse Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textDark,
                  ),
                ),
                const Text(
                  'Cash Out to Warehouses',
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerBtn(
                        label: 'Start Date',
                        date: _startDate,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DatePickerBtn(
                        label: 'End Date',
                        date: _endDate,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                    if (_startDate != null || _endDate != null)
                      IconButton(
                        onPressed: () => setState(() {
                          _startDate = null;
                          _endDate = null;
                        }),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColor.textMuted, size: 20),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                child: Text('No transactions found',
                    style: TextStyle(color: AppColor.textMuted)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final t = filtered[i];
                return _WarehouseTxCard(
                  warehouseName: t['warehouse']!,
                  userName: t['user']!,
                  amount: t['amount']!,
                  date: t['date']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseTxCard extends StatelessWidget {
  final String warehouseName;
  final String userName;
  final String amount;
  final String date;

  const _WarehouseTxCard({
    required this.warehouseName,
    required this.userName,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warehouse_rounded,
                color: AppColor.cashOut, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(warehouseName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColor.textDark)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 12, color: AppColor.textMuted),
                    const SizedBox(width: 4),
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- $amount',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.cashOut,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 11, color: AppColor.textMuted),
                  const SizedBox(width: 3),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _DatePickerBtn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerBtn(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColor.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: AppColor.primary),
            const SizedBox(width: 6),
            Text(
              date == null
                  ? label
                  : '${date!.day}/${date!.month}/${date!.year}',
              style: TextStyle(
                fontSize: 12,
                color: date == null
                    ? AppColor.textMuted
                    : AppColor.textDark,
                fontWeight: date == null
                    ? FontWeight.w400
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
