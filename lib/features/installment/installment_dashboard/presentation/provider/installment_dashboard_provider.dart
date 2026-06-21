import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/data/installment_dashboard_mock.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_summary.dart';

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

/// Top stat cards ka summary (abhi mock).
final installmentSummaryProvider =
    Provider<InstallmentSummary>((ref) => kInstallmentSummaryMock);

/// Search box ki current query.
final installmentSearchProvider = StateProvider<String>((ref) => '');

/// Selected filter chip.
final installmentFilterProvider =
    StateProvider<InstallmentFilter>((ref) => InstallmentFilter.all);

/// Filter + search apply karke final customer list.
final installmentCustomersProvider = Provider<List<InstallmentCustomer>>((ref) {
  final filter = ref.watch(installmentFilterProvider);
  final query = ref.watch(installmentSearchProvider).trim().toLowerCase();

  Iterable<InstallmentCustomer> list = kInstallmentCustomersMock;

  list = switch (filter) {
    InstallmentFilter.all => list,
    InstallmentFilter.active =>
      list.where((c) => c.status == InstallmentStatus.active),
    InstallmentFilter.completed =>
      list.where((c) => c.status == InstallmentStatus.completed),
    InstallmentFilter.overdue =>
      list.where((c) => c.status == InstallmentStatus.overdue),
  };

  if (query.isNotEmpty) {
    list = list.where((c) =>
        c.name.toLowerCase().contains(query) ||
        c.productsSearchText.contains(query));
  }

  return list.toList();
});
