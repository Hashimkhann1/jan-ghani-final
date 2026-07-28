// =============================================================
// employee_repository.dart
// Employees CRUD + salary/advance payments + monthly status.
//
// Har payment par 3 cheezein:
//   1. warehouse_cash_transactions (entry_type='salary') → cash minus (trigger)
//   2. warehouse_expenses (head='Salary', usi cash_txn se linked) → total expense
//   3. warehouse_salary_payments → per-employee tracking
// (Cash sirf 1 baar minus — expense row apna cash_txn NAHI banati.)
// =============================================================

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/data/warehouse_finance_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import '../domain/employee_model.dart';
import '../domain/employee_month_status.dart';
import '../domain/salary_payment_model.dart';

class EmployeeRepository {
  static final EmployeeRepository instance = EmployeeRepository._();
  EmployeeRepository._();

  Future<Connection> get _db  => DatabaseService.getConnection();
  String             get _wid => AppConfig.warehouseId;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  // ─────────────────────────────────────────────────────────
  // EMPLOYEES CRUD
  // ─────────────────────────────────────────────────────────
  Future<List<EmployeeModel>> getAllEmployees() async {
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT id, warehouse_id, name, phone, address,
               monthly_salary, max_advance_percent, is_active,
               created_at, updated_at, deleted_at
        FROM warehouse_employees
        WHERE warehouse_id = @wid AND deleted_at IS NULL
        ORDER BY name ASC
      '''),
      parameters: {'wid': _wid},
    );
    return result
        .map((r) => EmployeeModel.fromMap(r.toColumnMap()))
        .toList();
  }

  Future<EmployeeModel> addEmployee(EmployeeModel e) async {
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_employees (
          id, warehouse_id, name, phone, address,
          monthly_salary, max_advance_percent, is_active
        ) VALUES (
          @id, @wid, @name, @phone, @address,
          @salary, @advPct, @active
        )
        RETURNING *
      '''),
      parameters: {
        'id':      e.id.isEmpty ? const Uuid().v4() : e.id,
        'wid':     _wid,
        'name':    e.name,
        'phone':   e.phone,
        'address': e.address,
        'salary':  e.monthlySalary,
        'advPct':  e.maxAdvancePercent,
        'active':  e.isActive,
      },
    );
    return EmployeeModel.fromMap(result.first.toColumnMap());
  }

  Future<EmployeeModel> updateEmployee(EmployeeModel e) async {
    final conn = await _db;
    await conn.execute(
      Sql.named('''
        UPDATE warehouse_employees SET
          name = @name, phone = @phone, address = @address,
          monthly_salary = @salary, max_advance_percent = @advPct,
          is_active = @active, updated_at = NOW(), is_synced = false
        WHERE id = @id AND warehouse_id = @wid
      '''),
      parameters: {
        'id':      e.id,
        'wid':     _wid,
        'name':    e.name,
        'phone':   e.phone,
        'address': e.address,
        'salary':  e.monthlySalary,
        'advPct':  e.maxAdvancePercent,
        'active':  e.isActive,
      },
    );
    return e;
  }

  Future<void> deleteEmployee(String id) async {
    final conn = await _db;
    await conn.execute(
      Sql.named('''
        UPDATE warehouse_employees
        SET deleted_at = NOW(), is_synced = false
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );
  }

  // ─────────────────────────────────────────────────────────
  // SALARY PAYMENTS
  // ─────────────────────────────────────────────────────────
  Future<List<SalaryPaymentModel>> getPaymentsForMonth(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT id, warehouse_id, employee_id, cash_transaction_id,
               payment_type, amount, salary_month, notes,
               paid_by, paid_by_name, created_at, updated_at, deleted_at
        FROM warehouse_salary_payments
        WHERE warehouse_id = @wid
          AND salary_month = @month
          AND deleted_at IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'wid': _wid, 'month': first.toIso8601String().substring(0, 10)},
    );
    return result
        .map((r) => SalaryPaymentModel.fromMap(r.toColumnMap()))
        .toList();
  }

  Future<List<SalaryPaymentModel>> getPaymentsForEmployee(
      String employeeId) async {
    final conn = await _db;
    final result = await conn.execute(
      Sql.named('''
        SELECT id, warehouse_id, employee_id, cash_transaction_id,
               payment_type, amount, salary_month, notes,
               paid_by, paid_by_name, created_at, updated_at, deleted_at
        FROM warehouse_salary_payments
        WHERE warehouse_id = @wid
          AND employee_id  = @eid
          AND deleted_at IS NULL
        ORDER BY created_at DESC
      '''),
      parameters: {'wid': _wid, 'eid': employeeId},
    );
    return result
        .map((r) => SalaryPaymentModel.fromMap(r.toColumnMap()))
        .toList();
  }

  // Salary / advance pay karo — 3 inserts (ek transaction jaisa).
  Future<void> paySalary({
    required EmployeeModel employee,
    required SalaryPaymentType type,
    required double amount,
    required DateTime salaryMonth,
    String? notes,
    String? paidBy,
    String? paidByName,
  }) async {
    final first    = DateTime(salaryMonth.year, salaryMonth.month, 1);
    final payId    = const Uuid().v4();
    final monthLbl = '${_months[first.month - 1]} ${first.year}';
    final typeLbl  = type == SalaryPaymentType.advance ? 'Advance' : 'Salary';
    final noteText =
        '$typeLbl — ${employee.name} — $monthLbl${(notes != null && notes.trim().isNotEmpty) ? ' (${notes.trim()})' : ''}';

    // 1. cash_transaction (entry_type='salary') → cash minus (trigger)
    final cashTx = await WarehouseFinanceRepository.instance.addSalaryEntry(
      amount:          amount,
      salaryPaymentId: payId,
      notes:           noteText,
      createdBy:       paidBy,
      createdByName:   paidByName,
    );

    final conn = await _db;

    // 2. warehouse_expenses row (head='Salary') → total expense mein count
    await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_expenses (
          id, warehouse_id, cash_transaction_id,
          expense_head, amount, description,
          expense_date, created_by, created_by_name
        ) VALUES (
          @id, @wid, @cashTxId,
          'Salary', @amount, @desc,
          NOW(), @createdBy, @createdByName
        )
      '''),
      parameters: {
        'id':            const Uuid().v4(),
        'wid':           _wid,
        'cashTxId':      cashTx.id,
        'amount':        amount,
        'desc':          noteText,
        'createdBy':     paidBy,
        'createdByName': paidByName,
      },
    );

    // 3. warehouse_salary_payments row → per-employee tracking
    await conn.execute(
      Sql.named('''
        INSERT INTO warehouse_salary_payments (
          id, warehouse_id, employee_id, cash_transaction_id,
          payment_type, amount, salary_month, notes,
          paid_by, paid_by_name
        ) VALUES (
          @id, @wid, @eid, @cashTxId,
          @type, @amount, @month, @notes,
          @paidBy, @paidByName
        )
      '''),
      parameters: {
        'id':         payId,
        'wid':        _wid,
        'eid':        employee.id,
        'cashTxId':   cashTx.id,
        'type':       SalaryPaymentModel.typeToString(type),
        'amount':     amount,
        'month':      first.toIso8601String().substring(0, 10),
        'notes':      notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'paidBy':     paidBy,
        'paidByName': paidByName,
      },
    );
  }

  // Payment delete karo — cash wapas (cash_txn amount → 0 se trigger recompute)
  // + linked expense row soft-delete + payment soft-delete.
  Future<void> deletePayment(SalaryPaymentModel p) async {
    final conn = await _db;

    if (p.cashTransactionId != null) {
      // Cash reverse: amount 0 → trigger cash_in_hand recompute (cash back)
      await conn.execute(
        Sql.named('''
          UPDATE warehouse_cash_transactions
          SET amount = 0, notes = COALESCE(notes, '') || ' (deleted)',
              is_synced = false
          WHERE id = @ctxId
        '''),
        parameters: {'ctxId': p.cashTransactionId},
      );
      // Linked expense row soft-delete → total expense se hat jaye
      await conn.execute(
        Sql.named('''
          UPDATE warehouse_expenses
          SET deleted_at = NOW(), is_synced = false
          WHERE cash_transaction_id = @ctxId
        '''),
        parameters: {'ctxId': p.cashTransactionId},
      );
    }

    await conn.execute(
      Sql.named('''
        UPDATE warehouse_salary_payments
        SET deleted_at = NOW(), is_synced = false
        WHERE id = @id
      '''),
      parameters: {'id': p.id},
    );
  }

  // ─────────────────────────────────────────────────────────
  // MONTHLY STATUS (salary tracking screen)
  // ─────────────────────────────────────────────────────────
  Future<List<EmployeeMonthStatus>> getMonthStatuses(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final results = await Future.wait([
      getAllEmployees(),
      getPaymentsForMonth(first),
    ]);
    final employees = results[0] as List<EmployeeModel>;
    final payments  = results[1] as List<SalaryPaymentModel>;

    // Sirf active employees ko salary cycle mein dikhao
    return employees.where((e) => e.isActive).map((e) {
      final empPayments =
          payments.where((p) => p.employeeId == e.id).toList();
      return EmployeeMonthStatus(
        employee: e,
        month:    first,
        payments: empPayments,
      );
    }).toList();
  }
}
