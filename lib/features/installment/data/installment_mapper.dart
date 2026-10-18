import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';

double _num(dynamic v) => v == null ? 0 : (v as num).toDouble();
DateTime _date(dynamic v) => DateTime.parse(v as String);

InstallmentStatus _planStatus(List<InstallmentDue> dues) {
  if (dues.isEmpty) return InstallmentStatus.active;
  final firstUnpaid = dues.where((d) => !d.isPaid).firstOrNull;
  if (firstUnpaid == null) return InstallmentStatus.completed;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = firstUnpaid.dueDate;
  return DateTime(due.year, due.month, due.day).isBefore(today)
      ? InstallmentStatus.overdue
      : InstallmentStatus.active;
}

InstallmentPlan installmentPlanFromRow(Map<String, dynamic> row) {
  final dues = [
    for (final s in (row['installment_schedule'] as List? ?? const []))
      InstallmentDue(
        id: s['id'] as String,
        number: s['number'] as int,
        dueDate: _date(s['due_date']),
        amount: _num(s['amount']),
        paidAmount: _num(s['paid_amount']),
      ),
  ]..sort((a, b) => a.number.compareTo(b.number));

  final numberById = {for (final d in dues) d.id: d.number};
  final payments = [
    for (final p in (row['installment_payment'] as List? ?? const []))
      InstallmentPayment(
        id: p['id'] as String,
        kind: p['kind'] as String,
        amount: _num(p['amount']),
        paidAt: _date(p['paid_at']),
        installmentNumber: numberById[p['schedule_id']],
        note: p['note'] as String?,
      ),
  ]..sort((a, b) => b.paidAt.compareTo(a.paidAt));

  final paidInstallments = payments
      .where((p) => !p.isAdvance)
      .fold<double>(0, (s, p) => s + p.amount);

  return InstallmentPlan(
    id: row['id'] as String,
    product: row['product_name'] as String,
    totalPayable: _num(row['total_payable']),
    paidAmount: paidInstallments,
    paidCount: dues.where((d) => d.isPaid).length,
    totalCount: (row['months'] as num).toInt(),
    status: _planStatus(dues),
    startDate: _date(row['start_date']),
    price: _num(row['price']),
    advance: _num(row['advance']),
    chargeRate: _num(row['charge_rate']),
    dues: dues,
    payments: payments,
  );
}

InstallmentCustomer installmentCustomerFromRow(Map<String, dynamic> row) {
  final plans = [
    for (final p in (row['installment_plan'] as List? ?? const []))
      installmentPlanFromRow(Map<String, dynamic>.from(p as Map)),
  ]..sort((a, b) => b.startDate.compareTo(a.startDate));

  return InstallmentCustomer(
    id: row['id'] as String,
    name: row['name'] as String,
    phone: (row['phone'] as String?) ?? '',
    cnic: (row['cnic'] as String?) ?? '',
    address: (row['address'] as String?) ?? '',
    amount: _num(row['amount']),
    createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
    plans: plans,
  );
}
