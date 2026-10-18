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

/// Schedule ki ek qist (database: installment_schedule).
class InstallmentDue {
  final String id;
  final int number;
  final DateTime dueDate;
  final double amount;
  final double paidAmount;

  const InstallmentDue({
    required this.id,
    required this.number,
    required this.dueDate,
    required this.amount,
    this.paidAmount = 0,
  });

  bool get isPaid => paidAmount >= amount - 0.5;
  double get remaining => (amount - paidAmount).clamp(0, double.infinity).toDouble();
}

/// Ek payment (database: installment_payment) — advance ya qist.
class InstallmentPayment {
  final String id;
  final String kind; // 'advance' | 'installment'
  final double amount;
  final DateTime paidAt;
  final int? installmentNumber;
  final String? note;

  const InstallmentPayment({
    required this.id,
    required this.kind,
    required this.amount,
    required this.paidAt,
    this.installmentNumber,
    this.note,
  });

  bool get isAdvance => kind == 'advance';
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

  /// Asli data (database): qeemat, advance, charge rate, schedule, payments.
  final double price;
  final double advance;
  final double chargeRate; // har mahine ka, jaise 0.025
  final List<InstallmentDue> dues;
  final List<InstallmentPayment> payments;

  const InstallmentPlan({
    required this.id,
    required this.product,
    required this.totalPayable,
    required this.paidAmount,
    required this.paidCount,
    required this.totalCount,
    required this.status,
    required this.startDate,
    this.price = 0,
    this.advance = 0,
    this.chargeRate = 0.025,
    this.dues = const [],
    this.payments = const [],
  });

  /// Agli unpaid qist (schedule ke hisaab se), na ho to null.
  InstallmentDue? get nextDue {
    for (final d in dues) {
      if (!d.isPaid) return d;
    }
    return null;
  }

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
  final String address;

  /// Database ka `amount` (outstanding) — plan banne se pehle 0.
  final double amount;
  final DateTime? createdAt;

  const InstallmentCustomer({
    required this.id,
    required this.name,
    required this.plans,
    this.phone = '',
    this.cnic = '',
    this.address = '',
    this.amount = 0,
    this.createdAt,
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
    // Abhi koi plan nahi (naya customer) — completed na dikhao.
    if (plans.isEmpty) return InstallmentStatus.active;
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
