// =============================================================
// salary_provider.dart — monthly salary tracking + pay/delete
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/employee_repository.dart';
import '../../domain/employee_model.dart';
import '../../domain/employee_month_status.dart';
import '../../domain/salary_payment_model.dart';

class SalaryState {
  final DateTime                  month;     // 1st of selected month
  final List<EmployeeMonthStatus> statuses;
  final bool                      isLoading;
  final bool                      isSaving;
  final String?                   errorMessage;

  const SalaryState({
    required this.month,
    this.statuses     = const [],
    this.isLoading    = false,
    this.isSaving     = false,
    this.errorMessage,
  });

  // Summary
  int    get totalEmployees => statuses.length;
  int    get paidCount      =>
      statuses.where((s) => s.status == SalaryStatus.paid).length;
  int    get pendingCount   =>
      statuses.where((s) => s.status == SalaryStatus.pending).length;
  int    get partialCount   =>
      statuses.where((s) => s.status == SalaryStatus.partial).length;
  double get totalPaid      =>
      statuses.fold(0.0, (s, e) => s + e.totalPaid);
  double get totalRemaining =>
      statuses.fold(0.0, (s, e) => s + e.remaining);

  SalaryState copyWith({
    DateTime?                  month,
    List<EmployeeMonthStatus>? statuses,
    bool?                      isLoading,
    bool?                      isSaving,
    String?                    errorMessage,
    bool                       clearError = false,
  }) {
    return SalaryState(
      month:        month     ?? this.month,
      statuses:     statuses  ?? this.statuses,
      isLoading:    isLoading ?? this.isLoading,
      isSaving:     isSaving  ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SalaryNotifier extends StateNotifier<SalaryState> {
  final EmployeeRepository _repo = EmployeeRepository.instance;

  SalaryNotifier()
      : super(SalaryState(
          month: DateTime(DateTime.now().year, DateTime.now().month, 1),
        )) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getMonthStatuses(state.month);
      state = state.copyWith(statuses: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Salary data load masla: $e');
    }
  }

  void setMonth(DateTime month) {
    state = state.copyWith(month: DateTime(month.year, month.month, 1));
    load();
  }

  void prevMonth() =>
      setMonth(DateTime(state.month.year, state.month.month - 1, 1));
  void nextMonth() =>
      setMonth(DateTime(state.month.year, state.month.month + 1, 1));

  // Pay salary/advance — returns error string ya null (success)
  Future<String?> pay({
    required EmployeeModel employee,
    required SalaryPaymentType type,
    required double amount,
    String? notes,
    String? paidBy,
    String? paidByName,
  }) async {
    if (amount <= 0) return 'Amount 0 se zyada hona chahiye';

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.paySalary(
        employee:    employee,
        type:        type,
        amount:      amount,
        salaryMonth: state.month,
        notes:       notes,
        paidBy:      paidBy,
        paidByName:  paidByName,
      );
      await load();
      state = state.copyWith(isSaving: false);
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Pay masla: $e');
      return 'Pay masla: $e';
    }
  }

  Future<void> deletePayment(SalaryPaymentModel p) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.deletePayment(p);
      await load();
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
          isSaving: false, errorMessage: 'Delete masla: $e');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final salaryProvider =
    StateNotifierProvider<SalaryNotifier, SalaryState>(
        (ref) => SalaryNotifier());
