import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/installment/data/installment_remote_datasource.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Filter chips ke options.
enum InstallmentFilter { all, active, completed, overdue }

extension InstallmentFilterX on InstallmentFilter {
  String get label => switch (this) {
        InstallmentFilter.all => 'All',
        InstallmentFilter.active => 'Active',
        InstallmentFilter.completed => 'Completed',
        InstallmentFilter.overdue => 'Overdue',
      };
}

final installmentRemoteProvider = Provider<InstallmentRemoteDatasource>(
  (ref) => InstallmentRemoteDatasource(Supabase.instance.client),
);

/// Saare installment customers (officer / owner) — plans, schedule, payments ke saath.
final installmentCustomersDataProvider =
    FutureProvider<List<InstallmentCustomer>>(
  (ref) => ref.watch(installmentRemoteProvider).fetchCustomers(),
);

/// Ek customer (customer portal ke liye — RLS sirf uska apna row deta hai).
final installmentCustomerProvider =
    FutureProvider.family<InstallmentCustomer?, String>(
  (ref, id) => ref.watch(installmentRemoteProvider).fetchCustomer(id),
);

/// Likhai (customer / plan / payment) ke baad data dobara load karo.
void refreshInstallments(WidgetRef ref) {
  ref.invalidate(installmentCustomersDataProvider);
  ref.invalidate(installmentCustomerProvider);
}

/// Top stat cards ka summary.
final installmentSummaryProvider = Provider<InstallmentSummary>((ref) {
  final list = ref.watch(installmentCustomersDataProvider).valueOrNull;
  if (list == null) return InstallmentSummary.empty;

  final now = DateTime.now();
  bool thisMonth(DateTime? d) =>
      d != null && d.year == now.year && d.month == now.month;

  final collected = list
      .expand((c) => c.plans)
      .expand((p) => p.payments)
      .where((p) => !p.isAdvance && thisMonth(p.paidAt.toLocal()))
      .fold<double>(0, (s, p) => s + p.amount);

  return InstallmentSummary(
    totalCustomers: list.length,
    newThisMonth: list.where((c) => thisMonth(c.createdAt?.toLocal())).length,
    activeCount: list
        .where((c) => c.plans.isNotEmpty && c.status == InstallmentStatus.active)
        .length,
    remainingTotal: list.fold<double>(0, (s, c) => s + c.totalRemaining),
    collectedThisMonth: collected,
  );
});

/// Search box ki current query.
final installmentSearchProvider = StateProvider<String>((ref) => '');

/// Selected filter chip.
final installmentFilterProvider =
    StateProvider<InstallmentFilter>((ref) => InstallmentFilter.all);

/// Filter + search apply karke final customer list.
final installmentCustomersProvider = Provider<List<InstallmentCustomer>>((ref) {
  final filter = ref.watch(installmentFilterProvider);
  final query = ref.watch(installmentSearchProvider).trim().toLowerCase();

  Iterable<InstallmentCustomer> list =
      ref.watch(installmentCustomersDataProvider).valueOrNull ?? const [];

  list = switch (filter) {
    InstallmentFilter.all => list,
    InstallmentFilter.active => list.where(
        (c) => c.plans.isNotEmpty && c.status == InstallmentStatus.active),
    InstallmentFilter.completed =>
      list.where((c) => c.plans.isNotEmpty && c.status == InstallmentStatus.completed),
    InstallmentFilter.overdue =>
      list.where((c) => c.status == InstallmentStatus.overdue),
  };

  if (query.isNotEmpty) {
    list = list.where((c) =>
        c.name.toLowerCase().contains(query) ||
        c.phone.contains(query) ||
        c.productsSearchText.contains(query));
  }

  return list.toList();
});
