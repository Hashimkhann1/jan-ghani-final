

import 'package:jan_ghani_final/utils/dialogs/customer_dialogs/customer_detail_dialogs.dart';

class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double creditLimit;
  final double balance;
  final double totalPurchases;
  final int points;
  final String address;
  final String notes;
  final int totalOrders;
  final DateTime? customerSince;
  final List<CustomerOrder> orders;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.creditLimit = 0,
    this.balance = 0,
    this.totalPurchases = 0,
    this.points = 0,
    this.address = '',
    this.notes = '',
    this.totalOrders = 0,
    this.customerSince,
    this.orders = const [],
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  double get available => creditLimit - balance;
  double get creditUsagePercent =>
      creditLimit == 0 ? 0 : (balance / creditLimit).clamp(0, 1);
}