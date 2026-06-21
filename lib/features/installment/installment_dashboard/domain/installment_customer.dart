import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

/// Installment plan ki haalat (poore plan ka status).
enum InstallmentStatus { active, overdue, completed }

extension InstallmentStatusX on InstallmentStatus {
  String get label => switch (this) {
        InstallmentStatus.active => 'Active',
        InstallmentStatus.overdue => 'Overdue',
        InstallmentStatus.completed => 'Completed',
      };

  /// Accent / text color (top-border, paid count, progress bar).
  Color get color => switch (this) {
        InstallmentStatus.active => AppColor.primary,
        InstallmentStatus.overdue => AppColor.error,
        InstallmentStatus.completed => AppColor.success,
      };

  /// Badge ka light background.
  Color get bgColor => switch (this) {
        InstallmentStatus.active => const Color(0xFFEDEBFE),
        InstallmentStatus.overdue => AppColor.errorLight,
        InstallmentStatus.completed => AppColor.successLight,
      };
}

/// Ek product ka installment plan (ek customer ke multiple ho sakte hain).
class InstallmentPlan {
  final String id;
  final String product;
  final double totalPayable;
  final double paidAmount;
  final int paidCount;
  final int totalCount;
  final InstallmentStatus status;
  final DateTime startDate;

  const InstallmentPlan({
    required this.id,
    required this.product,
    required this.totalPayable,
    required this.paidAmount,
    required this.paidCount,
    required this.totalCount,
    required this.status,
    required this.startDate,
  });

  double get remaining =>
      (totalPayable - paidAmount).clamp(0, double.infinity).toDouble();

  /// 0.0 – 1.0 (amount-based).
  double get progress =>
      totalPayable == 0 ? 0 : (paidAmount / totalPayable).clamp(0, 1).toDouble();

  String get paidLabel =>
      '${paidCount.toString().padLeft(2, '0')}/${totalCount.toString().padLeft(2, '0')} paid';
}

/// Customer + uske saare installment plans (aggregate getters ke saath).
class InstallmentCustomer {
  final String id;
  final String name;
  final List<InstallmentPlan> plans;
  final String phone;
  final String cnic;

  const InstallmentCustomer({
    required this.id,
    required this.name,
    required this.plans,
    this.phone = '',
    this.cnic = '',
  });

  int get planCount => plans.length;

  double get totalPayable =>
      plans.fold(0.0, (sum, p) => sum + p.totalPayable);

  double get totalPaid => plans.fold(0.0, (sum, p) => sum + p.paidAmount);

  double get totalRemaining =>
      (totalPayable - totalPaid).clamp(0, double.infinity).toDouble();

  /// Aggregate amount-based progress (saari plans milakar).
  double get progress =>
      totalPayable == 0 ? 0 : (totalPaid / totalPayable).clamp(0, 1).toDouble();

  int get progressPercent => (progress * 100).round();

  /// Priority: koi plan overdue → overdue; koi active → active; warna completed.
  InstallmentStatus get status {
    if (plans.any((p) => p.status == InstallmentStatus.overdue)) {
      return InstallmentStatus.overdue;
    }
    if (plans.any((p) => p.status == InstallmentStatus.active)) {
      return InstallmentStatus.active;
    }
    return InstallmentStatus.completed;
  }

  /// Card subtitle: ek plan ho to product, warna "Product +N more".
  String get planSummary {
    if (plans.isEmpty) return '—';
    if (plans.length == 1) return plans.first.product;
    return '${plans.first.product} +${plans.length - 1} more';
  }

  /// Search ke liye saare products ek string mein.
  String get productsSearchText =>
      plans.map((p) => p.product).join(' ').toLowerCase();

  /// Avatar ke liye naam ke initials (max 2).
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
