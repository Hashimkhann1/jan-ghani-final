// =============================================================
// test/features/warehouse/warehouse_finance/warehouse_finance_test.dart
// Complete test suite — Model + Provider + Notifier
// =============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/data/warehouse_finance_repository.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/domain/warehouse_finance_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/presentation/provider/warehouse_finance_provider/warehouse_finance_provider.dart';

import 'warehouse_finance_test.mocks.dart';

// ─────────────────────────────────────────────────────────────
// Mock generate karo:
//   flutter pub run build_runner build --delete-conflicting-outputs
// ─────────────────────────────────────────────────────────────
@GenerateMocks([WarehouseFinanceRepository])
void main() {
  // ──────────────────────────────────────────────────────────
  // SETUP: AppConfig + SharedPreferences mock
  // ──────────────────────────────────────────────────────────
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // AppConfig mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'assets/json/config.json') {
        const config =
            '{"app_mode":"warehouse","warehouse_id":"c519975f-bf0e-4747-b152-ea38fcbf7cc5",'
            '"warehouse_name":"Jan Ghani Warehouse 001","db_host":"localhost",'
            '"db_port":5432,"db_name":"warehouse_db","db_user":"warehouseuser",'
            '"db_password":"warehouseUser123"}';
        return ByteData.view(
            Uint8List.fromList(utf8.encode(config)).buffer);
      }
      return null;
    });
    await AppConfig.load();

    // SharedPreferences mock
    const MethodChannel channel =
    MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, dynamic>{};
      return null;
    });
  });

  // ──────────────────────────────────────────────────────────
  // TEST DATA — reusable fixtures
  // ──────────────────────────────────────────────────────────
  final tNow = DateTime(2025, 6, 15, 10, 30);
  const tWid = 'c519975f-bf0e-4747-b152-ea38fcbf7cc5';

  final tFinance = WarehouseFinanceModel(
    id:          'finance-001',
    warehouseId: tWid,
    cashInHand:  50000.0,
    updatedAt:   tNow,
  );

  final tFinanceUpdated = WarehouseFinanceModel(
    id:          'finance-001',
    warehouseId: tWid,
    cashInHand:  55000.0,
    updatedAt:   tNow,
  );

  CashTransactionModel makeTx({
    String id            = 'tx-001',
    String entryType     = 'cash_in',
    double amount        = 5000.0,
    double balanceBefore = 50000.0,
    double balanceAfter  = 55000.0,
    String? referenceId,
    String? notes,
  }) =>
      CashTransactionModel(
        id:               id,
        warehouseId:      tWid,
        entryType:        entryType,
        amount:           amount,
        cashInHandBefore: balanceBefore,
        cashInHandAfter:  balanceAfter,
        referenceId:      referenceId,
        notes:            notes,
        createdBy:        'user-001',
        createdByName:    'Ahmed',
        createdAt:        tNow,
        syncId:           'sync-001',
        isSynced:         false,
      );

  final tSummary = WarehouseFinanceSummary(
    cashInHand:       50000,
    todayCashIn:      10000,
    todayCashOut:     3000,
    thisMonthCashIn:  80000,
    thisMonthCashOut: 25000,
    totalSupplierDue: 15000,
  );

  // ══════════════════════════════════════════════════════════
  // GROUP 1 — WarehouseFinanceModel Tests
  // ══════════════════════════════════════════════════════════
  group('WarehouseFinanceModel', () {
    test('fromMap — valid map se model bane', () {
      final map = {
        'id':           'finance-001',
        'warehouse_id': tWid,
        'cash_in_hand': 50000.0,
        'updated_at':   tNow,
      };

      final model = WarehouseFinanceModel.fromMap(map);

      expect(model.id,          'finance-001');
      expect(model.warehouseId, tWid);
      expect(model.cashInHand,  50000.0);
      expect(model.updatedAt,   tNow);
    });

    test('fromMap — cash_in_hand string se double bane', () {
      final map = {
        'id':           'finance-001',
        'warehouse_id': tWid,
        'cash_in_hand': '12345.50',
        'updated_at':   tNow,
      };
      final model = WarehouseFinanceModel.fromMap(map);
      expect(model.cashInHand, 12345.50);
    });

    test('fromMap — cash_in_hand int se double bane', () {
      final map = {
        'id':           'finance-001',
        'warehouse_id': tWid,
        'cash_in_hand': 1000,
        'updated_at':   tNow,
      };
      final model = WarehouseFinanceModel.fromMap(map);
      expect(model.cashInHand, 1000.0);
      expect(model.cashInHand, isA<double>());
    });

    test('fromMap — updated_at string se DateTime bane', () {
      final map = {
        'id':           'finance-001',
        'warehouse_id': tWid,
        'cash_in_hand': 0.0,
        'updated_at':   '2025-06-15T10:30:00.000',
      };
      final model = WarehouseFinanceModel.fromMap(map);
      expect(model.updatedAt, isA<DateTime>());
    });

    test('copyWith — sirf cashInHand badla', () {
      final updated = tFinance.copyWith(cashInHand: 99999.0);
      expect(updated.cashInHand,  99999.0);
      expect(updated.id,          tFinance.id);
      expect(updated.warehouseId, tFinance.warehouseId);
      expect(updated.updatedAt,   tFinance.updatedAt);
    });

    test('copyWith — original unchanged rahe', () {
      tFinance.copyWith(cashInHand: 1.0);
      expect(tFinance.cashInHand, 50000.0);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 2 — CashTransactionModel Tests
  // ══════════════════════════════════════════════════════════
  group('CashTransactionModel', () {
    test('fromMap — valid map se model bane', () {
      final map = {
        'id':                  'tx-001',
        'warehouse_id':        tWid,
        'entry_type':          'cash_in',
        'amount':              5000.0,
        'cash_in_hand_before': 50000.0,
        'cash_in_hand_after':  55000.0,
        'reference_id':        null,
        'notes':               'Test cash in',
        'created_by':          'user-001',
        'created_by_name':     'Ahmed',
        'created_at':          tNow,
        'sync_id':             'sync-001',
        'is_synced':           false,
        'synced_at':           null,
      };

      final model = CashTransactionModel.fromMap(map);

      expect(model.id,               'tx-001');
      expect(model.entryType,        'cash_in');
      expect(model.amount,           5000.0);
      expect(model.cashInHandBefore, 50000.0);
      expect(model.cashInHandAfter,  55000.0);
      expect(model.isSynced,         false);
    });

    test('fromMap — is_synced null hoga toh false ho', () {
      final map = {
        'id':                  'tx-001',
        'warehouse_id':        tWid,
        'entry_type':          'purchase',
        'amount':              2000.0,
        'cash_in_hand_before': 10000.0,
        'cash_in_hand_after':  8000.0,
        'created_at':          tNow,
        'sync_id':             'sync-002',
        'is_synced':           null,
        'synced_at':           null,
      };
      final model = CashTransactionModel.fromMap(map);
      expect(model.isSynced, false);
    });

    test('fromMap — synced_at string se DateTime bane', () {
      final map = {
        'id':                  'tx-001',
        'warehouse_id':        tWid,
        'entry_type':          'cash_in',
        'amount':              1000.0,
        'cash_in_hand_before': 0.0,
        'cash_in_hand_after':  1000.0,
        'created_at':          tNow,
        'sync_id':             'sync-001',
        'is_synced':           true,
        'synced_at':           '2025-06-15T11:00:00.000',
      };
      final model = CashTransactionModel.fromMap(map);
      expect(model.syncedAt, isA<DateTime>());
    });

    // entryTypeDisplay tests
    test('entryTypeDisplay — cash_in → "Cash In"', () {
      final tx = makeTx(entryType: 'cash_in');
      expect(tx.entryTypeDisplay, 'Cash In');
    });

    test('entryTypeDisplay — purchase → "Purchase"', () {
      final tx = makeTx(entryType: 'purchase');
      expect(tx.entryTypeDisplay, 'Purchase');
    });

    test('entryTypeDisplay — supplier_payment → "Supplier Payment"', () {
      final tx = makeTx(entryType: 'supplier_payment');
      expect(tx.entryTypeDisplay, 'Supplier Payment');
    });

    test('entryTypeDisplay — expense → "Expense"', () {
      final tx = makeTx(entryType: 'expense');
      expect(tx.entryTypeDisplay, 'Expense');
    });

    test('entryTypeDisplay — unknown type → same return ho', () {
      final tx = makeTx(entryType: 'other_type');
      expect(tx.entryTypeDisplay, 'other_type');
    });

    // isCashIn tests
    test('isCashIn — cash_in hoga toh true', () {
      expect(makeTx(entryType: 'cash_in').isCashIn, true);
    });

    test('isCashIn — purchase hoga toh false', () {
      expect(makeTx(entryType: 'purchase').isCashIn, false);
    });

    test('isCashIn — supplier_payment hoga toh false', () {
      expect(makeTx(entryType: 'supplier_payment').isCashIn, false);
    });

    test('isCashIn — expense hoga toh false', () {
      expect(makeTx(entryType: 'expense').isCashIn, false);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 3 — WarehouseFinanceSummary Tests
  // ══════════════════════════════════════════════════════════
  group('WarehouseFinanceSummary', () {
    test('todayNet — cashIn minus cashOut', () {
      expect(tSummary.todayNet, 7000.0); // 10000 - 3000
    });

    test('thisMonthNet — month cashIn minus cashOut', () {
      expect(tSummary.thisMonthNet, 55000.0); // 80000 - 25000
    });

    test('default constructor — sab zero hoga', () {
      const summary = WarehouseFinanceSummary();
      expect(summary.cashInHand,       0.0);
      expect(summary.todayCashIn,      0.0);
      expect(summary.todayCashOut,     0.0);
      expect(summary.thisMonthCashIn,  0.0);
      expect(summary.thisMonthCashOut, 0.0);
      expect(summary.totalSupplierDue, 0.0);
      expect(summary.todayNet,         0.0);
      expect(summary.thisMonthNet,     0.0);
    });

    test('todayNet — negative ho sakta hai (zyada out)', () {
      const s = WarehouseFinanceSummary(todayCashIn: 1000, todayCashOut: 3000);
      expect(s.todayNet, -2000.0);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 4 — WarehouseFinanceState Tests
  // ══════════════════════════════════════════════════════════
  group('WarehouseFinanceState', () {
    final tTx1 = makeTx(id: 'tx-001', entryType: 'cash_in');
    final tTx2 = makeTx(id: 'tx-002', entryType: 'purchase',
        balanceBefore: 55000, balanceAfter: 53000);
    final tTx3 = makeTx(id: 'tx-003', entryType: 'supplier_payment',
        balanceBefore: 53000, balanceAfter: 51000);
    final tTx4 = makeTx(id: 'tx-004', entryType: 'expense',
        balanceBefore: 51000, balanceAfter: 50000);

    final allTx = [tTx1, tTx2, tTx3, tTx4];

    test('default state — initial values sahi hon', () {
      const s = WarehouseFinanceState();
      expect(s.finance,      isNull);
      expect(s.transactions, isEmpty);
      expect(s.summary,      isNull);
      expect(s.isLoading,    false);
      expect(s.errorMessage, isNull);
      expect(s.activeFilter, 'all');
    });

    test('filteredTransactions — all filter pe sab mile', () {
      final s = WarehouseFinanceState(transactions: allTx, activeFilter: 'all');
      expect(s.filteredTransactions.length, 4);
    });

    test('filteredTransactions — cash_in filter pe sirf cash_in mile', () {
      final s = WarehouseFinanceState(
          transactions: allTx, activeFilter: 'cash_in');
      expect(s.filteredTransactions.length, 1);
      expect(s.filteredTransactions.first.entryType, 'cash_in');
    });

    test('filteredTransactions — purchase filter pe sirf purchase mile', () {
      final s = WarehouseFinanceState(
          transactions: allTx, activeFilter: 'purchase');
      expect(s.filteredTransactions.length, 1);
      expect(s.filteredTransactions.first.entryType, 'purchase');
    });

    test('filteredTransactions — supplier_payment filter', () {
      final s = WarehouseFinanceState(
          transactions: allTx, activeFilter: 'supplier_payment');
      expect(s.filteredTransactions.length, 1);
      expect(s.filteredTransactions.first.entryType, 'supplier_payment');
    });

    test('filteredTransactions — expense filter', () {
      final s = WarehouseFinanceState(
          transactions: allTx, activeFilter: 'expense');
      expect(s.filteredTransactions.length, 1);
      expect(s.filteredTransactions.first.entryType, 'expense');
    });

    test('filteredTransactions — koi match nahi toh empty list', () {
      final s = WarehouseFinanceState(
          transactions: allTx, activeFilter: 'unknown_type');
      expect(s.filteredTransactions, isEmpty);
    });

    test('copyWith — errorMessage update ho', () {
      const s = WarehouseFinanceState();
      final updated = s.copyWith(errorMessage: 'Test error');
      expect(updated.errorMessage, 'Test error');
    });

    test('copyWith — isLoading toggle ho', () {
      const s = WarehouseFinanceState();
      final loading = s.copyWith(isLoading: true);
      expect(loading.isLoading, true);
      final done = loading.copyWith(isLoading: false);
      expect(done.isLoading, false);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 5 — WarehouseFinanceNotifier Tests
  // ══════════════════════════════════════════════════════════
  group('WarehouseFinanceNotifier', () {
    late MockWarehouseFinanceRepository mockRepo;
    late WarehouseFinanceNotifier       notifier;

    setUp(() {
      mockRepo = MockWarehouseFinanceRepository();

      // loadData() ke liye default stubs (constructor mein call hota hai)
      when(mockRepo.getOrCreate())
          .thenAnswer((_) async => tFinance);
      when(mockRepo.getTransactions())
          .thenAnswer((_) async => []);
      when(mockRepo.getSummary())
          .thenAnswer((_) async => tSummary);

      notifier = WarehouseFinanceNotifier(mockRepo);
    });

    tearDown(() {
      notifier.dispose();
    });

    // ── loadData ─────────────────────────────────────────
    group('loadData()', () {
      test('loadData — finance, transactions, summary load hon', () async {
        final tx = makeTx();
        when(mockRepo.getTransactions())
            .thenAnswer((_) async => [tx]);

        await notifier.loadData();

        expect(notifier.state.finance,          tFinance);
        expect(notifier.state.transactions,     [tx]);
        expect(notifier.state.summary,          tSummary);
        expect(notifier.state.isLoading,        false);
        expect(notifier.state.errorMessage,     isNull);
      });

      test('loadData — error pe errorMessage set ho', () async {
        when(mockRepo.getOrCreate())
            .thenThrow(Exception('DB connection fail'));
        when(mockRepo.getTransactions())
            .thenAnswer((_) async => []);
        when(mockRepo.getSummary())
            .thenAnswer((_) async => tSummary);

        await notifier.loadData();

        expect(notifier.state.isLoading,    false);
        expect(notifier.state.errorMessage, isNotNull);
        expect(notifier.state.errorMessage,
            contains('Data load karne mein masla'));
      });
    });

    // ── onFilterChanged ───────────────────────────────────
    group('onFilterChanged()', () {
      test('filter cash_in pe set ho', () async {
        await notifier.loadData();
        notifier.onFilterChanged('cash_in');
        expect(notifier.state.activeFilter, 'cash_in');
      });

      test('filter purchase pe set ho', () async {
        await notifier.loadData();
        notifier.onFilterChanged('purchase');
        expect(notifier.state.activeFilter, 'purchase');
      });

      test('filter all pe reset ho', () async {
        await notifier.loadData();
        notifier.onFilterChanged('purchase');
        notifier.onFilterChanged('all');
        expect(notifier.state.activeFilter, 'all');
      });
    });

    // ── addCashIn ─────────────────────────────────────────
    group('addCashIn()', () {
      test('addCashIn — success pe transaction list mein add ho', () async {
        await notifier.loadData();

        final newTx = makeTx(
          id:            'tx-new',
          entryType:     'cash_in',
          amount:        5000,
          balanceBefore: 50000,
          balanceAfter:  55000,
        );

        when(mockRepo.addCashIn(
          amount:        5000,
          notes:         'Test',
          createdBy:     'user-001',
          createdByName: 'Ahmed',
        )).thenAnswer((_) async => newTx);

        when(mockRepo.getOrCreate())
            .thenAnswer((_) async => tFinanceUpdated);

        await notifier.addCashIn(
          amount:   5000,
          notes:    'Test',
          userId:   'user-001',
          userName: 'Ahmed',
        );

        expect(notifier.state.isLoading,          false);
        expect(notifier.state.errorMessage,       isNull);
        expect(notifier.state.transactions.first, newTx);
        expect(notifier.state.finance?.cashInHand, 55000.0);
      });

      test('addCashIn — summary todayCashIn update ho', () async {
        // initial summary set karo
        when(mockRepo.getSummary()).thenAnswer((_) async => tSummary);
        await notifier.loadData();

        final newTx = makeTx(entryType: 'cash_in', amount: 5000);
        when(mockRepo.addCashIn(
          amount:        5000,
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenAnswer((_) async => newTx);
        when(mockRepo.getOrCreate())
            .thenAnswer((_) async => tFinanceUpdated);

        await notifier.addCashIn(amount: 5000);

        // todayCashIn = 10000 + 5000 = 15000
        expect(notifier.state.summary?.todayCashIn, 15000.0);
      });

      test('addCashIn — error pe errorMessage set ho', () async {
        await notifier.loadData();

        when(mockRepo.addCashIn(
          amount:        anyNamed('amount'),
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenThrow(Exception('Insert fail'));

        await notifier.addCashIn(amount: 5000);

        expect(notifier.state.isLoading,    false);
        expect(notifier.state.errorMessage, contains('Cash in entry mein masla'));
      });
    });

    // ── addSupplierPayment ────────────────────────────────
    group('addSupplierPayment()', () {
      test('success pe transaction add ho aur finance update ho', () async {
        await notifier.loadData();

        final newTx = makeTx(
          id:          'tx-sup',
          entryType:   'supplier_payment',
          amount:      3000,
          referenceId: 'sup-001',
        );

        when(mockRepo.addSupplierPayment(
          amount:        3000,
          supplierId:    'sup-001',
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenAnswer((_) async => newTx);
        when(mockRepo.getOrCreate())
            .thenAnswer((_) async => tFinanceUpdated);

        await notifier.addSupplierPayment(
          amount:     3000,
          supplierId: 'sup-001',
        );

        expect(notifier.state.isLoading,          false);
        expect(notifier.state.errorMessage,       isNull);
        expect(notifier.state.transactions.first, newTx);
      });

      test('error pe errorMessage set ho', () async {
        await notifier.loadData();
        when(mockRepo.addSupplierPayment(
          amount:        anyNamed('amount'),
          supplierId:    anyNamed('supplierId'),
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenThrow(Exception('Supplier payment fail'));

        await notifier.addSupplierPayment(amount: 3000, supplierId: 'sup-001');

        expect(notifier.state.errorMessage,
            contains('Supplier payment entry mein masla'));
      });
    });

    // ── addPurchaseEntry ──────────────────────────────────
    group('addPurchaseEntry()', () {
      test('success pe transaction add ho', () async {
        await notifier.loadData();

        final newTx = makeTx(
          id:          'tx-po',
          entryType:   'purchase',
          amount:      8000,
          referenceId: 'po-001',
        );

        when(mockRepo.addPurchaseEntry(
          amount:        8000,
          poId:          'po-001',
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenAnswer((_) async => newTx);
        when(mockRepo.getOrCreate())
            .thenAnswer((_) async => tFinanceUpdated);

        await notifier.addPurchaseEntry(amount: 8000, poId: 'po-001');

        expect(notifier.state.isLoading,          false);
        expect(notifier.state.transactions.first, newTx);
      });

      test('error pe errorMessage set ho', () async {
        await notifier.loadData();
        when(mockRepo.addPurchaseEntry(
          amount:        anyNamed('amount'),
          poId:          anyNamed('poId'),
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenThrow(Exception('PO insert fail'));

        await notifier.addPurchaseEntry(amount: 8000, poId: 'po-001');

        expect(notifier.state.errorMessage,
            contains('Purchase entry mein masla'));
      });
    });

    // ── addExpenseEntry ───────────────────────────────────
    group('addExpenseEntry()', () {
      test('success pe transaction add ho', () async {
        await notifier.loadData();

        final newTx = makeTx(
          id:          'tx-exp',
          entryType:   'expense',
          amount:      1500,
          referenceId: 'exp-001',
        );

        when(mockRepo.addExpenseEntry(
          amount:        1500,
          expenseId:     'exp-001',
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenAnswer((_) async => newTx);
        when(mockRepo.getOrCreate())
            .thenAnswer((_) async => tFinanceUpdated);

        await notifier.addExpenseEntry(amount: 1500, expenseId: 'exp-001');

        expect(notifier.state.isLoading,          false);
        expect(notifier.state.transactions.first, newTx);
      });

      test('error pe errorMessage set ho', () async {
        await notifier.loadData();
        when(mockRepo.addExpenseEntry(
          amount:        anyNamed('amount'),
          expenseId:     anyNamed('expenseId'),
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenThrow(Exception('Expense insert fail'));

        await notifier.addExpenseEntry(amount: 1500, expenseId: 'exp-001');

        expect(notifier.state.errorMessage,
            contains('Expense entry mein masla'));
      });
    });

    // ── Multiple transactions ─────────────────────────────
    group('Multiple Transactions', () {
      test('nayi transaction list ke shuruaat mein aati hai', () async {
        final existingTx = makeTx(id: 'tx-old', entryType: 'cash_in');

        when(mockRepo.getTransactions())
            .thenAnswer((_) async => [existingTx]);
        when(mockRepo.getSummary()).thenAnswer((_) async => tSummary);
        await notifier.loadData();

        expect(notifier.state.transactions.length, 1);

        final newTx = makeTx(id: 'tx-new', entryType: 'cash_in', amount: 2000);
        when(mockRepo.addCashIn(
          amount:        2000,
          notes:         anyNamed('notes'),
          createdBy:     anyNamed('createdBy'),
          createdByName: anyNamed('createdByName'),
        )).thenAnswer((_) async => newTx);
        when(mockRepo.getOrCreate())
            .thenAnswer((_) async => tFinanceUpdated);

        await notifier.addCashIn(amount: 2000);

        expect(notifier.state.transactions.length,  2);
        expect(notifier.state.transactions.first.id, 'tx-new');
        expect(notifier.state.transactions.last.id,  'tx-old');
      });
    });

    // ── Filter + Transactions combined ───────────────────
    group('Filter + Transactions', () {
      test('loadData ke baad filter apply ho', () async {
        final txList = [
          makeTx(id: 'tx-1', entryType: 'cash_in'),
          makeTx(id: 'tx-2', entryType: 'purchase'),
          makeTx(id: 'tx-3', entryType: 'expense'),
        ];
        when(mockRepo.getTransactions())
            .thenAnswer((_) async => txList);
        when(mockRepo.getSummary()).thenAnswer((_) async => tSummary);

        await notifier.loadData();
        notifier.onFilterChanged('expense');

        expect(notifier.state.filteredTransactions.length, 1);
        expect(
            notifier.state.filteredTransactions.first.entryType, 'expense');
      });
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 6 — Real PostgreSQL Data Tests
  // Actual DB se copy kiya hua data — production bugs pakadne ke liye
  // Table: public.warehouse_finance
  // ══════════════════════════════════════════════════════════
  group('Real DB Data — WarehouseFinanceModel', () {
    // Exact postgres row:
    // id:           "1c26bd08-f9f2-40cb-bd3d-8fa86384f14a"
    // warehouse_id: "c519975f-bf0e-4747-b152-ea38fcbf7cc5"
    // cash_in_hand: 206918.00
    // updated_at:   "2026-04-18 21:45:01.424698+05"
    // is_synced:    true
    // synced_at:    "2026-04-18 12:08:45.015761+05"

    // Postgres se aane wala exact map (DateTime object ke tor pe)
    final realMap = {
      'id':           '1c26bd08-f9f2-40cb-bd3d-8fa86384f14a',
      'warehouse_id': 'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
      'cash_in_hand': 206918.00,
      'updated_at':   DateTime.parse('2026-04-18 21:45:01.424698+05:00'),
      'is_synced':    true,
      'synced_at':    DateTime.parse('2026-04-18 12:08:45.015761+05:00'),
    };

    test('fromMap — real id sahi parse ho', () {
      final model = WarehouseFinanceModel.fromMap(realMap);
      expect(model.id, '1c26bd08-f9f2-40cb-bd3d-8fa86384f14a');
    });

    test('fromMap — real warehouse_id sahi parse ho', () {
      final model = WarehouseFinanceModel.fromMap(realMap);
      expect(model.warehouseId, 'c519975f-bf0e-4747-b152-ea38fcbf7cc5');
    });

    test('fromMap — cash_in_hand 206918.00 exact match ho', () {
      final model = WarehouseFinanceModel.fromMap(realMap);
      expect(model.cashInHand, 206918.00);
      expect(model.cashInHand, isA<double>());
    });

    test('fromMap — updated_at timezone ke saath sahi parse ho', () {
      final model = WarehouseFinanceModel.fromMap(realMap);
      expect(model.updatedAt, isA<DateTime>());
      expect(model.updatedAt.year,  2026);
      expect(model.updatedAt.month, 4);
      expect(model.updatedAt.day,   18);
    });

    // String format test — jab postgres driver string return kare
    test('fromMap — updated_at string format "+05" ke saath parse ho', () {
      final mapWithString = {
        'id':           '1c26bd08-f9f2-40cb-bd3d-8fa86384f14a',
        'warehouse_id': 'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
        'cash_in_hand': 206918.00,
        'updated_at':   '2026-04-18 21:45:01.424698+05:00',
      };
      final model = WarehouseFinanceModel.fromMap(mapWithString);
      expect(model.updatedAt, isA<DateTime>());
      expect(model.updatedAt.year, 2026);
    });

    test('fromMap — cash_in_hand numeric string se bhi parse ho', () {
      final mapWithString = {
        'id':           '1c26bd08-f9f2-40cb-bd3d-8fa86384f14a',
        'warehouse_id': 'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
        'cash_in_hand': '206918.00',   // string ke tor pe
        'updated_at':   DateTime.parse('2026-04-18 21:45:01.424698+05:00'),
      };
      final model = WarehouseFinanceModel.fromMap(mapWithString);
      expect(model.cashInHand, 206918.00);
    });

    test('copyWith — real data pe cashInHand update ho, baaki same rahe', () {
      final model   = WarehouseFinanceModel.fromMap(realMap);
      final updated = model.copyWith(cashInHand: 210000.00);

      expect(updated.cashInHand,  210000.00);
      expect(updated.id,          '1c26bd08-f9f2-40cb-bd3d-8fa86384f14a');
      expect(updated.warehouseId, 'c519975f-bf0e-4747-b152-ea38fcbf7cc5');
      expect(updated.updatedAt,   model.updatedAt);
    });

    test('copyWith — original real model unchanged rahe', () {
      final model = WarehouseFinanceModel.fromMap(realMap);
      model.copyWith(cashInHand: 999.0);
      expect(model.cashInHand, 206918.00);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 7 — Real DB Data: CashTransactionModel
  // is_synced=true aur synced_at non-null case
  // ══════════════════════════════════════════════════════════
  group('Real DB Data — CashTransactionModel', () {
    // is_synced = true wala transaction (synced ho chuka)
    final realTxMap = {
      'id':                  'abc12345-0000-0000-0000-000000000001',
      'warehouse_id':        'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
      'entry_type':          'cash_in',
      'amount':              206918.00,
      'cash_in_hand_before': 0.0,
      'cash_in_hand_after':  206918.00,
      'reference_id':        null,
      'notes':               'Opening balance',
      'created_by':          'user-001',
      'created_by_name':     'Hashim',
      'created_at':          DateTime.parse('2026-04-18 21:45:01.424698+05:00'),
      'sync_id':             'sync-abc-001',
      'is_synced':           true,   // ← real data mein true tha
      'synced_at':           DateTime.parse('2026-04-18 12:08:45.015761+05:00'),
    };

    test('fromMap — is_synced = true sahi parse ho', () {
      final tx = CashTransactionModel.fromMap(realTxMap);
      expect(tx.isSynced, true);
    });

    test('fromMap — synced_at non-null DateTime ho', () {
      final tx = CashTransactionModel.fromMap(realTxMap);
      expect(tx.syncedAt, isNotNull);
      expect(tx.syncedAt, isA<DateTime>());
      expect(tx.syncedAt!.year,  2026);
      expect(tx.syncedAt!.month, 4);
      expect(tx.syncedAt!.day,   18);
    });

    test('fromMap — synced_at string "+05:00" ke saath parse ho', () {
      final mapWithString = {
        ...realTxMap,
        'synced_at': '2026-04-18 12:08:45.015761+05:00',
        'created_at': DateTime.parse('2026-04-18 21:45:01.424698+05:00'),
      };
      final tx = CashTransactionModel.fromMap(mapWithString);
      expect(tx.syncedAt, isNotNull);
      expect(tx.syncedAt!.year, 2026);
    });

    test('fromMap — amount 206918.00 exact match ho', () {
      final tx = CashTransactionModel.fromMap(realTxMap);
      expect(tx.amount, 206918.00);
    });

    test('isCashIn — real data cash_in entry pe true ho', () {
      final tx = CashTransactionModel.fromMap(realTxMap);
      expect(tx.isCashIn, true);
    });

    test('entryTypeDisplay — real cash_in entry "Cash In" return kare', () {
      final tx = CashTransactionModel.fromMap(realTxMap);
      expect(tx.entryTypeDisplay, 'Cash In');
    });

    // Synced transaction ka balance check
    test('fromMap — cashInHandAfter = cashInHandBefore + amount ho', () {
      final tx = CashTransactionModel.fromMap(realTxMap);
      expect(tx.cashInHandAfter,
          tx.cashInHandBefore + tx.amount);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 8 — Real Data: WarehouseFinanceSummary
  // Actual cashInHand value se summary computed fields
  // ══════════════════════════════════════════════════════════
  group('Real DB Data — WarehouseFinanceSummary', () {
    test('cashInHand 206918.00 se summary bane', () {
      const summary = WarehouseFinanceSummary(
        cashInHand:       206918.00,
        todayCashIn:      206918.00,
        todayCashOut:     0,
        thisMonthCashIn:  206918.00,
        thisMonthCashOut: 0,
        totalSupplierDue: 0,
      );

      expect(summary.cashInHand,      206918.00);
      expect(summary.todayNet,        206918.00);   // 206918 - 0
      expect(summary.thisMonthNet,    206918.00);
      expect(summary.totalSupplierDue, 0.0);
    });

    test('todayNet — cashOut hone ke baad balance sahi ho', () {
      const summary = WarehouseFinanceSummary(
        cashInHand:   206918.00,
        todayCashIn:  206918.00,
        todayCashOut: 50000.00,
      );
      expect(summary.todayNet, 156918.00); // 206918 - 50000
    });
  });
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER TEST HELPER — direct state set karo (optional)
// ─────────────────────────────────────────────────────────────
extension WarehouseFinanceNotifierTestHelper on WarehouseFinanceNotifier {
  void loadTestState({
    WarehouseFinanceModel?     finance,
    List<CashTransactionModel> transactions = const [],
    WarehouseFinanceSummary?   summary,
    String                     activeFilter = 'all',
  }) {
    state = state.copyWith(
      finance:      finance,
      transactions: transactions,
      summary:      summary,
      isLoading:    false,
      activeFilter: activeFilter,
    );
  }
}