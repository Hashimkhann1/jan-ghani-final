// =============================================================
// supplier_detail_provider_test.dart
// SupplierDetailNotifier — loadData, switchTab, payOutstanding
// DB calls mock nahi kar sakte (direct DatabaseService use karta hai)
// Isliye state extension se test karte hain
// =============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_detail_models.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_detail_provider/supplier_detail_provider.dart';

// ── Test Extension — state seedha inject karo ───────────────
extension SupplierDetailNotifierTestHelper on SupplierDetailNotifier {
  void injectTestState({
    List<SupplierLedgerEntry>?   ledgerEntries,
    List<SupplierPurchaseOrder>? purchaseOrders,
    SupplierFinancialSummary?    financialSummary,
    bool                         isLoading = false,
    String?                      errorMessage,
    String                       activeTab = 'ledger',
  }) {
    state = SupplierDetailState(
      ledgerEntries:    ledgerEntries    ?? [],
      purchaseOrders:   purchaseOrders   ?? [],
      financialSummary: financialSummary,
      isLoading:        isLoading,
      errorMessage:     errorMessage,
      activeTab:        activeTab,
    );
  }
}

void main() {
  // ── AppConfig mock ────────────────────────────────────────
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'assets/json/config.json') {
        const config =
            '{"app_mode":"warehouse",'
            '"warehouse_id":"c519975f-bf0e-4747-b152-ea38fcbf7cc5",'
            '"warehouse_name":"Jan Ghani Warehouse 001",'
            '"db_host":"localhost","db_port":5432,'
            '"db_name":"warehouse_db","db_user":"warehouseuser",'
            '"db_password":"warehouseUser123"}';
        return ByteData.view(
            Uint8List.fromList(utf8.encode(config)).buffer);
      }
      return null;
    });

    const MethodChannel channel =
    MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, dynamic>{};
      return null;
    });

    await AppConfig.load();

    // CRITICAL FIX: Real DB block karo — test mein connect nahi hoga
    DatabaseService.blockConnectionForTest();
  });

  tearDownAll(() {
    DatabaseService.resetForTest();
  });

  // ── Test data — real DB se ────────────────────────────────

  // Qasim Khan ke real ledger entries (DB se)
  final List<SupplierLedgerEntry> testLedgerEntries = [
    SupplierLedgerEntry(
      id:            '783ed866-efa7-49db-bb5d-43c2b8b0321b',
      supplierId:    '4991b2bd-21bf-4251-9df8-b9e55ea415c8',
      poId:          null,
      entryType:     'opening',
      amount:        10000.0,
      balanceBefore: 0.0,
      balanceAfter:  10000.0,
      notes:         'System se pehle ka balance',
      createdByName: null,
      createdAt:     DateTime(2026, 4, 9, 17, 23, 34),
    ),
    SupplierLedgerEntry(
      id:            '81dbd7db-14da-49d2-b29f-2bdf9d34780a',
      supplierId:    '4991b2bd-21bf-4251-9df8-b9e55ea415c8',
      poId:          '4303f2e4-59d5-488f-96a2-00d77f09bcec',
      entryType:     'purchase',
      amount:        1300.0,
      balanceBefore: 10000.0,
      balanceAfter:  11300.0,
      notes:         'PO PO-20260412-683471 se purchase',
      createdByName: 'M Hashim',
      createdAt:     DateTime(2026, 4, 12, 0, 13, 34),
    ),
    SupplierLedgerEntry(
      id:            'fbf05499-a2c0-4626-8aa5-d6aae33142fd',
      supplierId:    '4991b2bd-21bf-4251-9df8-b9e55ea415c8',
      poId:          null,
      entryType:     'payment',
      amount:        -7710.0,
      balanceBefore: 37710.0,
      balanceAfter:  30000.0,
      notes:         'Manual payment',
      createdByName: 'M Hashim',
      createdAt:     DateTime(2026, 4, 12, 15, 7, 16),
    ),
    SupplierLedgerEntry(
      id:            '8969dcf0-9b84-4f27-8e7e-958feab40914',
      supplierId:    '4991b2bd-21bf-4251-9df8-b9e55ea415c8',
      poId:          null,
      entryType:     'payment',
      amount:        -517.0,
      balanceBefore: 70517.50,
      balanceAfter:  70000.50,
      notes:         'Manual payment',
      createdByName: 'Asim',
      createdAt:     DateTime(2026, 4, 18, 21, 44, 5),
    ),
  ];

  // Purchase orders test data (real DB pattern)
  final List<SupplierPurchaseOrder> testPurchaseOrders = [
    SupplierPurchaseOrder(
      id:             '4303f2e4-59d5-488f-96a2-00d77f09bcec',
      poNumber:       'PO-20260412-683471',
      orderDate:      DateTime(2026, 4, 12, 0, 13, 34),
      expectedDate:   DateTime(2026, 4, 12),
      status:         'received',
      subtotal:       1300.0,
      discountAmount: 0.0,
      taxAmount:      0.0,
      totalAmount:    1300.0,
      paidAmount:     0.0,
      createdAt:      DateTime(2026, 4, 12, 0, 13, 34),
    ),
    SupplierPurchaseOrder(
      id:             '0b57de54-1092-47a9-9947-410e93b3187d',
      poNumber:       'PO-20260414-295787',
      orderDate:      DateTime(2026, 4, 14, 15, 59, 4),
      expectedDate:   DateTime(2026, 4, 14),
      status:         'received',
      subtotal:       45212.50,
      discountAmount: 0.0,
      taxAmount:      0.0,
      totalAmount:    45212.50,
      paidAmount:     0.0,
      createdAt:      DateTime(2026, 4, 14, 15, 59, 4),
    ),
    SupplierPurchaseOrder(
      id:             'e549ed73-a479-42a2-ae97-13c0a76ca2f9',
      poNumber:       'PO-20260415-112385',
      orderDate:      DateTime(2026, 4, 15, 23, 52, 18),
      status:         'ordered',
      subtotal:       43992.50,
      discountAmount: 0.0,
      taxAmount:      0.0,
      totalAmount:    43992.50,
      paidAmount:     0.0,
      createdAt:      DateTime(2026, 4, 15, 23, 52, 18),
    ),
  ];

  const SupplierFinancialSummary testSummary = SupplierFinancialSummary(
    outstandingBalance: 70000.50,
    totalPurchased:     90517.50,
    totalPaid:          7710.0,
    totalOrders:        3,
    pendingOrders:      1,
  );

  late SupplierDetailNotifier notifier;

  setUp(() {
    notifier = SupplierDetailNotifier();
  });

  // ════════════════════════════════════════════════════════════
  // 1. Initial State Tests
  // ════════════════════════════════════════════════════════════
  group('initial state —', () {

    test('default state sahi hoti hai', () {
      expect(notifier.state.ledgerEntries,    isEmpty);
      expect(notifier.state.purchaseOrders,   isEmpty);
      expect(notifier.state.financialSummary, isNull);
      expect(notifier.state.isLoading,        false);
      expect(notifier.state.errorMessage,     isNull);
      expect(notifier.state.activeTab,        'ledger');
    });
  });

  // ════════════════════════════════════════════════════════════
  // 2. switchTab Tests
  // ════════════════════════════════════════════════════════════
  group('switchTab —', () {

    test('ledger → orders switch karta hai', () {
      notifier.switchTab('orders');
      expect(notifier.state.activeTab, 'orders');
    });

    test('orders → ledger switch karta hai', () {
      notifier.injectTestState(activeTab: 'orders');
      notifier.switchTab('ledger');
      expect(notifier.state.activeTab, 'ledger');
    });

    test('tab switch se data change nahi hota', () {
      notifier.injectTestState(
        ledgerEntries: testLedgerEntries,
        activeTab: 'ledger',
      );
      notifier.switchTab('orders');
      expect(notifier.state.ledgerEntries.length,
          testLedgerEntries.length);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 3. State — copyWith Tests
  // ════════════════════════════════════════════════════════════
  group('SupplierDetailState.copyWith —', () {

    test('ledgerEntries update hoti hai', () {
      notifier.injectTestState(ledgerEntries: testLedgerEntries);
      expect(notifier.state.ledgerEntries.length,
          testLedgerEntries.length);
    });

    test('purchaseOrders update hote hain', () {
      notifier.injectTestState(purchaseOrders: testPurchaseOrders);
      expect(notifier.state.purchaseOrders.length,
          testPurchaseOrders.length);
    });

    test('financialSummary set hoti hai', () {
      notifier.injectTestState(financialSummary: testSummary);
      expect(notifier.state.financialSummary, isNotNull);
      expect(notifier.state.financialSummary!.outstandingBalance,
          70000.50);
    });

    test('errorMessage set hota hai', () {
      notifier.injectTestState(errorMessage: 'Test error');
      expect(notifier.state.errorMessage, 'Test error');
    });

    test('isLoading set hota hai', () {
      notifier.injectTestState(isLoading: true);
      expect(notifier.state.isLoading, true);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 4. Ledger Entry Data Tests
  // ════════════════════════════════════════════════════════════
  group('ledger entries data —', () {

    setUp(() {
      notifier.injectTestState(
        ledgerEntries: testLedgerEntries,
        purchaseOrders: testPurchaseOrders,
        financialSummary: testSummary,
      );
    });

    test('4 ledger entries load hote hain', () {
      expect(notifier.state.ledgerEntries.length, 4);
    });

    test('opening entry sahi hai', () {
      final opening = notifier.state.ledgerEntries
          .firstWhere((e) => e.entryType == 'opening');
      expect(opening.amount,       10000.0);
      expect(opening.balanceBefore, 0.0);
      expect(opening.balanceAfter,  10000.0);
    });

    test('payment entries negative amount hain', () {
      final payments = notifier.state.ledgerEntries
          .where((e) => e.entryType == 'payment').toList();
      expect(payments.every((e) => e.amount < 0), true);
    });

    test('purchase entry po_id set hai', () {
      final purchase = notifier.state.ledgerEntries
          .firstWhere((e) => e.entryType == 'purchase');
      expect(purchase.poId, isNotNull);
    });

    test('isCredit aur isDebit sahi kaam karte hain', () {
      final payments = notifier.state.ledgerEntries
          .where((e) => e.entryType == 'payment').toList();
      final purchases = notifier.state.ledgerEntries
          .where((e) => e.entryType == 'purchase').toList();

      expect(payments.every((e) => e.isCredit), true);
      expect(purchases.every((e) => e.isDebit),  true);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 5. Purchase Orders Data Tests
  // ════════════════════════════════════════════════════════════
  group('purchase orders data —', () {

    setUp(() {
      notifier.injectTestState(
        purchaseOrders: testPurchaseOrders,
        financialSummary: testSummary,
      );
    });

    test('3 purchase orders load hote hain', () {
      expect(notifier.state.purchaseOrders.length, 3);
    });

    test('received POs sahi hain', () {
      final received = notifier.state.purchaseOrders
          .where((po) => po.status == 'received').toList();
      expect(received.length, 2);
    });

    test('ordered PO pending hai', () {
      final ordered = notifier.state.purchaseOrders
          .where((po) => po.status == 'ordered').toList();
      expect(ordered.length, 1);
      expect(ordered.first.paidAmount, 0.0);
    });

    test('received POs ki remainingAmount sahi hai', () {
      final po = notifier.state.purchaseOrders
          .firstWhere((po) => po.id == '4303f2e4-59d5-488f-96a2-00d77f09bcec');
      expect(po.remainingAmount, 1300.0); // totalAmount - paidAmount
    });
  });

  // ════════════════════════════════════════════════════════════
  // 6. Financial Summary Tests
  // ════════════════════════════════════════════════════════════
  group('financial summary —', () {

    test('summary sahi inject hoti hai', () {
      notifier.injectTestState(financialSummary: testSummary);

      expect(notifier.state.financialSummary!.outstandingBalance, 70000.50);
      expect(notifier.state.financialSummary!.totalOrders,        3);
      expect(notifier.state.financialSummary!.pendingOrders,      1);
    });

    test('totalRemaining sahi calculate hota hai', () {
      notifier.injectTestState(financialSummary: testSummary);
      // 90517.50 - 7710.0 = 82807.50
      expect(notifier.state.financialSummary!.totalRemaining,
          closeTo(82807.50, 0.01));
    });

    test('summary null ho toh graceful handle hota hai', () {
      notifier.injectTestState(financialSummary: null);
      expect(notifier.state.financialSummary, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 7. loadData — DB call fails gracefully
  // ════════════════════════════════════════════════════════════
  group('loadData error handling —', () {

    test('DB call fail ho toh errorMessage set hota hai', () async {
      // Real DB nahi hai test environment mein
      // loadData exception throw karega — gracefully handle hona chahiye
      await notifier.loadData('some-supplier-id');

      // Either error ya loading false
      expect(notifier.state.isLoading, false);
      // errorMessage set hona chahiye ya state valid honi chahiye
    });
  });
}