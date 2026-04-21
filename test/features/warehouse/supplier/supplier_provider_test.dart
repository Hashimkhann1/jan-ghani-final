// =============================================================
// supplier_provider_test.dart
// SupplierNotifier — loadSuppliers, addSupplier, updateSupplier,
// deleteSupplier, toggleStatus, payOutstanding,
// search/filter, computed stats
//
// Run karne se pehle mock generate karo:
// flutter pub run build_runner build --delete-conflicting-outputs
// =============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_provider/supplier_provider.dart';

import 'mock_supplier_repository.mocks.dart';

// ── Test helper — notifier mein state seedha load karo ──────
extension SupplierNotifierTestHelper on SupplierNotifier {
  void loadTestSuppliers(List<SupplierModel> suppliers) {
    state = state.copyWith(allSuppliers: suppliers, isLoading: false);
  }
}

void main() {
  // ── AppConfig mock setup ─────────────────────────────────
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

    // SharedPreferences mock
    const MethodChannel channel =
    MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, dynamic>{};
      return null;
    });

    await AppConfig.load();
  });

  // ── Test suppliers — real DB se ──────────────────────────
  final SupplierModel qasimKhan = SupplierModel(
    id:                  '4991b2bd-21bf-4251-9df8-b9e55ea415c8',
    warehouseId:         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    name:                'Qasim Khan',
    companyName:         'Coka Cola',
    contactPerson:       '0313000000',
    email:               'qasim@gmail.com',
    phone:               '0313000000',
    address:             'nka asnjfbs ahajsbf',
    code:                'SUPP-0003',
    taxId:               '889755',
    paymentTerms:        30,
    isActive:            true,
    notes:               'this is the testing database',
    createdById:         'a3f74bae-4a49-412a-bb51-c7166981ea3a',
    createdByName:       'M Hashim',
    createdAt:           DateTime(2026, 4, 9, 17, 23, 34),
    updatedAt:           DateTime(2026, 4, 18, 21, 45, 1),
    outstandingBalance:  70000.50,
    totalOrders:         8,
    totalPurchaseAmount: 95000.0,
  );

  final SupplierModel sabirKhan = SupplierModel(
    id:                  '85e7ba3a-0f97-4bc9-9df9-9bf26a74535e',
    warehouseId:         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    name:                'Sabir Khan',
    companyName:         'Jan Ghani',
    contactPerson:       '0313000000',
    email:               'sabir@gmail.com',
    phone:               '03130000000',
    address:             'gull abad pull',
    code:                'SUPP-0004',
    taxId:               '8509325',
    paymentTerms:        30,
    isActive:            true,
    notes:               'abb opening balance test kar raha ho.',
    createdById:         'a3f74bae-4a49-412a-bb51-c7166981ea3a',
    createdByName:       'M Hashim',
    createdAt:           DateTime(2026, 4, 9, 17, 46, 50),
    updatedAt:           DateTime(2026, 4, 18, 21, 42, 5),
    outstandingBalance:  0.0,
    totalOrders:         0,
    totalPurchaseAmount: 0.0,
  );

  final SupplierModel mHashimTesting = SupplierModel(
    id:                  '79181d20-7422-4745-867a-07f879763b7b',
    warehouseId:         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    name:                'M Hashim',
    companyName:         'Testing',
    contactPerson:       '03130000000',
    email:               'hashim@gmaiil.com',
    phone:               '0313000000',
    address:             'charsadda sardhari',
    code:                'SUPP-0002',
    taxId:               '8978656',
    paymentTerms:        30,
    isActive:            true,
    notes:               'daa yoo testing supplier',
    createdById:         'a3f74bae-4a49-412a-bb51-c7166981ea3a',
    createdByName:       'M Hashim',
    createdAt:           DateTime(2026, 4, 9, 16, 43, 44),
    updatedAt:           DateTime(2026, 4, 18, 12, 8, 46),
    outstandingBalance:  100000.58,
    totalOrders:         10,
    totalPurchaseAmount: 220000.0,
  );

  final SupplierModel deletedHashim = SupplierModel(
    id:                  '7838e06b-6857-41ce-aede-2f2d592dcaf7',
    warehouseId:         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    name:                'M Hashim',
    companyName:         'Pepsi',
    phone:               '03139217887',
    paymentTerms:        45,
    isActive:            true,
    createdAt:           DateTime(2026, 4, 9, 16, 30, 24),
    updatedAt:           DateTime(2026, 4, 18, 12, 8, 45),
    deletedAt:           DateTime(2026, 4, 9, 16, 35, 55),
    outstandingBalance:  0.0,
    totalOrders:         0,
    totalPurchaseAmount: 0.0,
  );

  final SupplierModel inactiveSupplier = SupplierModel(
    id:                  'inactive-001',
    warehouseId:         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    name:                'Inactive Supplier',
    phone:               '03001234567',
    paymentTerms:        30,
    isActive:            false,
    createdAt:           DateTime(2026, 1, 1),
    updatedAt:           DateTime(2026, 1, 1),
    outstandingBalance:  0.0,
    totalOrders:         2,
    totalPurchaseAmount: 50000.0,
  );

  late MockSupplierRepository mockRepo;
  late SupplierNotifier notifier;

  setUp(() {
    mockRepo = MockSupplierRepository();
    // loadSuppliers constructor mein call hoti hai — default empty return
    when(mockRepo.getAll()).thenAnswer((_) async => []);
    notifier = SupplierNotifier(mockRepo);
  });

  // ════════════════════════════════════════════════════════════
  // 1. loadSuppliers Tests
  // ════════════════════════════════════════════════════════════
  group('loadSuppliers —', () {

    test('success — suppliers list load hoti hai', () async {
      when(mockRepo.getAll())
          .thenAnswer((_) async => [qasimKhan, sabirKhan, mHashimTesting]);

      await notifier.loadSuppliers();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.allSuppliers.length, 3);
      expect(notifier.state.errorMessage, isNull);
    });

    test('success — empty list bhi chal jata hai', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => []);

      await notifier.loadSuppliers();

      expect(notifier.state.allSuppliers, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('loading state — loading ke waqt true hota hai', () async {
      when(mockRepo.getAll()).thenAnswer((_) async {
        expect(notifier.state.isLoading, true); // loading ke andar check
        return [];
      });

      await notifier.loadSuppliers();
    });

    test('error — exception pe errorMessage set hota hai', () async {
      when(mockRepo.getAll())
          .thenThrow(Exception('DB connection failed'));

      await notifier.loadSuppliers();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.errorMessage,
          contains('Suppliers load karne mein masla'));
    });

    test('real data — 6 suppliers load hote hain', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [
        qasimKhan, sabirKhan, mHashimTesting,
        deletedHashim, inactiveSupplier,
        qasimKhan.copyWith(
          name: 'M Asim',
          outstandingBalance: 44000.0,
        ),
      ]);

      await notifier.loadSuppliers();

      expect(notifier.state.allSuppliers.length, 6);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 2. filteredSuppliers Tests
  // ════════════════════════════════════════════════════════════
  group('filteredSuppliers —', () {

    setUp(() {
      notifier.loadTestSuppliers([
        qasimKhan,
        sabirKhan,
        mHashimTesting,
        deletedHashim,    // deleted — filter mein nahi aana chahiye
        inactiveSupplier,
      ]);
    });

    test('deleted suppliers filter mein nahi aate', () {
      final filtered = notifier.state.filteredSuppliers;
      final ids = filtered.map((s) => s.id).toList();
      expect(ids.contains(deletedHashim.id), false);
    });

    test('filterStatus: all — active aur inactive dono aate hain', () {
      notifier.onFilterChanged('all');
      final filtered = notifier.state.filteredSuppliers;
      // deleted wala nahi aata, baaki sab
      expect(filtered.length, 4);
    });

    test('filterStatus: active — sirf active suppliers', () {
      notifier.onFilterChanged('active');
      final filtered = notifier.state.filteredSuppliers;
      expect(filtered.every((s) => s.isActive), true);
      // inactiveSupplier nahi aana chahiye
      expect(filtered.any((s) => s.id == 'inactive-001'), false);
    });

    test('filterStatus: inactive — sirf inactive suppliers', () {
      notifier.onFilterChanged('inactive');
      final filtered = notifier.state.filteredSuppliers;
      expect(filtered.every((s) => !s.isActive), true);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'inactive-001');
    });

    test('searchQuery — name se search', () {
      notifier.onSearchChanged('Qasim');
      final filtered = notifier.state.filteredSuppliers;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Qasim Khan');
    });

    test('searchQuery — case insensitive', () {
      notifier.onSearchChanged('qasim');
      final filtered = notifier.state.filteredSuppliers;
      expect(filtered.length, 1);
    });

    test('searchQuery — companyName se bhi search hota hai', () {
      notifier.onSearchChanged('Coka');
      final filtered = notifier.state.filteredSuppliers;
      expect(filtered.any((s) => s.companyName == 'Coka Cola'), true);
    });

    test('searchQuery — phone se search', () {
      notifier.onSearchChanged('03130000000');
      final filtered = notifier.state.filteredSuppliers;
      expect(filtered.isNotEmpty, true);
    });

    test('searchQuery — empty query sab dikhata hai', () {
      notifier.onSearchChanged('');
      final filtered = notifier.state.filteredSuppliers;
      expect(filtered.length, 4); // deleted wala nahi
    });

    test('searchQuery — no match — empty list', () {
      notifier.onSearchChanged('xyz_no_match_12345');
      final filtered = notifier.state.filteredSuppliers;
      expect(filtered, isEmpty);
    });

    test('search + filter combine hote hain', () {
      notifier.onFilterChanged('active');
      notifier.onSearchChanged('M Hashim');
      final filtered = notifier.state.filteredSuppliers;
      // M Hashim (Testing) active hai toh aayega
      expect(filtered.every((s) => s.isActive), true);
      expect(filtered.every((s) =>
          s.name.toLowerCase().contains('m hashim')), true);
    });
  });

  // ════════════════════════════════════════════════════════════
  // 3. Computed Stats Tests
  // ════════════════════════════════════════════════════════════
  group('computed stats —', () {

    setUp(() {
      notifier.loadTestSuppliers([
        qasimKhan,       // active, balance 70000.50
        sabirKhan,       // active, balance 0
        mHashimTesting,  // active, balance 100000.58
        deletedHashim,   // deleted
        inactiveSupplier, // inactive
      ]);
    });

    test('totalCount — deleted nahi ginte', () {
      expect(notifier.state.totalCount, 4); // deletedHashim exclude
    });

    test('activeCount — sirf active wale', () {
      expect(notifier.state.activeCount, 3);
      // qasimKhan, sabirKhan, mHashimTesting active hain
    });

    test('totalPurchased — sab ka sum', () {
      // 95000 + 0 + 220000 + 0 + 50000 = 365000
      expect(notifier.state.totalPurchased, 365000.0);
    });

    test('totalOutstanding — sirf positive balances sum', () {
      // 70000.50 + 0 + 100000.58 + 0 + 0 = 170001.08
      expect(notifier.state.totalOutstanding,
          closeTo(170001.08, 0.01));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 4. addSupplier Tests
  // ════════════════════════════════════════════════════════════
  group('addSupplier —', () {

    test('success — supplier list mein add hota hai', () async {
      final newSupplier = SupplierModel(
        id:                  'new-sup-001',
        warehouseId:         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
        name:                'New Supplier',
        phone:               '03001234567',
        paymentTerms:        30,
        isActive:            true,
        createdAt:           DateTime.now(),
        updatedAt:           DateTime.now(),
        outstandingBalance:  0.0,
        totalOrders:         0,
        totalPurchaseAmount: 0.0,
      );

      when(mockRepo.insert(any, openingBalance: anyNamed('openingBalance')))
          .thenAnswer((_) async => newSupplier);

      notifier.loadTestSuppliers([qasimKhan, sabirKhan]);
      await notifier.addSupplier(newSupplier);

      expect(notifier.state.allSuppliers.length, 3);
      expect(notifier.state.allSuppliers.last.id, 'new-sup-001');
      expect(notifier.state.isLoading, false);
    });

    test('success — opening balance ke saath', () async {
      when(mockRepo.insert(any, openingBalance: 5000.0))
          .thenAnswer((_) async => qasimKhan.copyWith(
          outstandingBalance: 5000.0));

      notifier.loadTestSuppliers([]);
      await notifier.addSupplier(qasimKhan, openingBalance: 5000.0);

      verify(mockRepo.insert(any, openingBalance: 5000.0)).called(1);
    });

    test('error — exception pe errorMessage set hota hai', () async {
      when(mockRepo.insert(any, openingBalance: anyNamed('openingBalance')))
          .thenThrow(Exception('Insert failed'));

      notifier.loadTestSuppliers([]);
      await notifier.addSupplier(qasimKhan);

      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.errorMessage,
          contains('Supplier save karne mein masla'));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 5. updateSupplier Tests
  // ════════════════════════════════════════════════════════════
  group('updateSupplier —', () {

    test('success — existing supplier update hota hai', () async {
      final updatedQasim = qasimKhan.copyWith(name: 'Qasim Khan Updated');

      when(mockRepo.update(any))
          .thenAnswer((_) async => updatedQasim);

      notifier.loadTestSuppliers([qasimKhan, sabirKhan]);
      await notifier.updateSupplier(updatedQasim);

      final found = notifier.state.allSuppliers
          .firstWhere((s) => s.id == qasimKhan.id);
      expect(found.name, 'Qasim Khan Updated');
      expect(notifier.state.allSuppliers.length, 2); // count same
    });

    test('success — doosre suppliers untouched rehte hain', () async {
      when(mockRepo.update(any))
          .thenAnswer((_) async => qasimKhan.copyWith(phone: '03000000000'));

      notifier.loadTestSuppliers([qasimKhan, sabirKhan]);
      await notifier.updateSupplier(qasimKhan);

      final sabirInState = notifier.state.allSuppliers
          .firstWhere((s) => s.id == sabirKhan.id);
      expect(sabirInState.name, 'Sabir Khan');
    });

    test('error — exception pe errorMessage', () async {
      when(mockRepo.update(any))
          .thenThrow(Exception('Update failed'));

      notifier.loadTestSuppliers([qasimKhan]);
      await notifier.updateSupplier(qasimKhan);

      expect(notifier.state.errorMessage,
          contains('Supplier update karne mein masla'));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 6. deleteSupplier Tests
  // ════════════════════════════════════════════════════════════
  group('deleteSupplier (soft delete) —', () {

    test('success — deletedAt set ho jata hai', () async {
      when(mockRepo.softDelete(any)).thenAnswer((_) async => {});

      notifier.loadTestSuppliers([qasimKhan, sabirKhan]);
      await notifier.deleteSupplier(qasimKhan.id);

      final deleted = notifier.state.allSuppliers
          .firstWhere((s) => s.id == qasimKhan.id);
      expect(deleted.deletedAt, isNotNull);
    });

    test('soft delete — filteredSuppliers se remove hota hai', () async {
      when(mockRepo.softDelete(any)).thenAnswer((_) async => {});

      notifier.loadTestSuppliers([qasimKhan, sabirKhan]);
      await notifier.deleteSupplier(qasimKhan.id);

      final filtered = notifier.state.filteredSuppliers;
      expect(filtered.any((s) => s.id == qasimKhan.id), false);
    });

    test('allSuppliers mein record rehta hai (soft delete)', () async {
      when(mockRepo.softDelete(any)).thenAnswer((_) async => {});

      notifier.loadTestSuppliers([qasimKhan, sabirKhan]);
      await notifier.deleteSupplier(qasimKhan.id);

      // allSuppliers mein hona chahiye (deletedAt se filter hota hai)
      expect(notifier.state.allSuppliers.length, 2);
    });

    test('error — exception pe errorMessage', () async {
      when(mockRepo.softDelete(any))
          .thenThrow(Exception('Delete failed'));

      notifier.loadTestSuppliers([qasimKhan]);
      await notifier.deleteSupplier(qasimKhan.id);

      expect(notifier.state.errorMessage,
          contains('Supplier delete karne mein masla'));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 7. toggleStatus Tests
  // ════════════════════════════════════════════════════════════
  group('toggleStatus —', () {

    test('active → inactive toggle hota hai', () async {
      when(mockRepo.toggleStatus(any, any)).thenAnswer((_) async => {});

      notifier.loadTestSuppliers([qasimKhan]);
      await notifier.toggleStatus(qasimKhan.id, false);

      final supplier = notifier.state.allSuppliers
          .firstWhere((s) => s.id == qasimKhan.id);
      expect(supplier.isActive, false);
    });

    test('inactive → active toggle hota hai', () async {
      when(mockRepo.toggleStatus(any, any)).thenAnswer((_) async => {});

      notifier.loadTestSuppliers([inactiveSupplier]);
      await notifier.toggleStatus(inactiveSupplier.id, true);

      final supplier = notifier.state.allSuppliers
          .firstWhere((s) => s.id == inactiveSupplier.id);
      expect(supplier.isActive, true);
    });

    test('error — errorMessage set hota hai', () async {
      when(mockRepo.toggleStatus(any, any))
          .thenThrow(Exception('Toggle failed'));

      notifier.loadTestSuppliers([qasimKhan]);
      await notifier.toggleStatus(qasimKhan.id, false);

      expect(notifier.state.errorMessage,
          contains('Status update karne mein masla'));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 8. payOutstanding Tests
  // ════════════════════════════════════════════════════════════
  group('payOutstanding —', () {

    test('success — balance reduce hota hai', () async {
      final afterPayment = qasimKhan.copyWith(
          outstandingBalance: 20000.50); // 70000.50 - 50000

      when(mockRepo.payToSupplier(
        supplierId: anyNamed('supplierId'),
        amount:     anyNamed('amount'),
        notes:      anyNamed('notes'),
        userId:     anyNamed('userId'),
      )).thenAnswer((_) async => afterPayment);

      notifier.loadTestSuppliers([qasimKhan, sabirKhan]);
      await notifier.payOutstanding(
        supplierId: qasimKhan.id,
        amount:     50000.0,
        notes:      'Cash payment',
        userId:     'a3f74bae-4a49-412a-bb51-c7166981ea3a',
      );

      final supplier = notifier.state.allSuppliers
          .firstWhere((s) => s.id == qasimKhan.id);
      expect(supplier.outstandingBalance, 20000.50);
      expect(notifier.state.isLoading, false);
    });

    test('success — full payment — balance 0 ho jata hai', () async {
      final fullyPaid = qasimKhan.copyWith(outstandingBalance: 0.0);

      when(mockRepo.payToSupplier(
        supplierId: anyNamed('supplierId'),
        amount:     anyNamed('amount'),
        notes:      anyNamed('notes'),
        userId:     anyNamed('userId'),
      )).thenAnswer((_) async => fullyPaid);

      notifier.loadTestSuppliers([qasimKhan]);
      await notifier.payOutstanding(
        supplierId: qasimKhan.id,
        amount:     70000.50,
        userId:     'a3f74bae-4a49-412a-bb51-c7166981ea3a',
      );

      final supplier = notifier.state.allSuppliers
          .firstWhere((s) => s.id == qasimKhan.id);
      expect(supplier.outstandingBalance, 0.0);
      expect(supplier.isClear, true);
    });

    test('success — doosre suppliers untouched rehte hain', () async {
      when(mockRepo.payToSupplier(
        supplierId: anyNamed('supplierId'),
        amount:     anyNamed('amount'),
        notes:      anyNamed('notes'),
        userId:     anyNamed('userId'),
      )).thenAnswer((_) async => qasimKhan.copyWith(
          outstandingBalance: 20000.0));

      notifier.loadTestSuppliers([qasimKhan, sabirKhan]);
      await notifier.payOutstanding(
          supplierId: qasimKhan.id, amount: 50000.0);

      final sabir = notifier.state.allSuppliers
          .firstWhere((s) => s.id == sabirKhan.id);
      expect(sabir.outstandingBalance, 0.0); // unchanged
    });

    test('error — exception pe errorMessage', () async {
      when(mockRepo.payToSupplier(
        supplierId: anyNamed('supplierId'),
        amount:     anyNamed('amount'),
        notes:      anyNamed('notes'),
        userId:     anyNamed('userId'),
      )).thenThrow(Exception('Payment failed'));

      notifier.loadTestSuppliers([qasimKhan]);
      await notifier.payOutstanding(
          supplierId: qasimKhan.id, amount: 5000.0);

      expect(notifier.state.errorMessage,
          contains('Payment record karne mein masla'));
    });
  });

  // ════════════════════════════════════════════════════════════
  // 9. onSearchChanged / onFilterChanged Tests
  // ════════════════════════════════════════════════════════════
  group('state updates —', () {

    test('onSearchChanged — searchQuery update hota hai', () {
      notifier.onSearchChanged('Qasim');
      expect(notifier.state.searchQuery, 'Qasim');
    });

    test('onFilterChanged — filterStatus update hota hai', () {
      notifier.onFilterChanged('active');
      expect(notifier.state.filterStatus, 'active');
    });

    test('search reset — empty string se reset', () {
      notifier.onSearchChanged('something');
      notifier.onSearchChanged('');
      expect(notifier.state.searchQuery, '');
    });

    test('filter default value — all', () {
      expect(notifier.state.filterStatus, 'all');
    });
  });
}