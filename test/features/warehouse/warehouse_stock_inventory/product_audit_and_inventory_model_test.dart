// =============================================================
// product_audit_and_inventory_model_test.dart
// Tests for:
//   1. ProductAuditLog.changedFields
//   2. WarehouseStockInventory.fromJson / toJson
//   3. WarehouseStockInventory edge cases (null safety issues)
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/datasource/product_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/warehouse_stock_inventory_model.dart';

void main() {

  // ══════════════════════════════════════════════════════════
  // GROUP 1: ProductAuditLog
  // ══════════════════════════════════════════════════════════
  group('ProductAuditLog —', () {

    ProductAuditLog makeLog({
      Map<String, dynamic>? oldData,
      Map<String, dynamic>? newData,
    }) {
      return ProductAuditLog(
        id:         'log-001',
        productId:  'prod-001',
        userName:   'M Hashim',
        changeType: 'update',
        oldData:    oldData,
        newData:    newData,
        changedAt:  DateTime(2026, 4, 18),
      );
    }

    test('changedFields — sahi fields return kare', () {
      final log = makeLog(
        oldData: {
          'name': 'Pepsi',
          'selling_price': '120.0',
          'quantity': '22.0',
        },
        newData: {
          'name': 'Pepsi',          // same — change nahi hua
          'selling_price': '145.0', // changed
          'quantity': '25.0',       // changed
        },
      );

      expect(log.changedFields, containsAll(['selling_price', 'quantity']));
      expect(log.changedFields, isNot(contains('name')));
    });

    test('changedFields — oldData null hone pe empty list', () {
      final log = makeLog(oldData: null, newData: {'name': 'Pepsi'});
      expect(log.changedFields, isEmpty);
    });

    test('changedFields — newData null hone pe empty list', () {
      final log = makeLog(
          oldData: {'name': 'Pepsi'}, newData: null);
      expect(log.changedFields, isEmpty);
    });

    test('changedFields — koi change nahi hota toh empty list', () {
      final data = {'name': 'Pepsi', 'selling_price': '120.0'};
      final log  = makeLog(oldData: data, newData: Map.from(data));
      expect(log.changedFields, isEmpty);
    });

    test('create type log mein oldData null hona chahiye', () {
      final log = ProductAuditLog(
        id: 'log-create', productId: 'prod-001',
        userName: 'Warehouse', changeType: 'create',
        oldData: null,
        newData: {'name': 'Dal', 'quantity': '25.0'},
        changedAt: DateTime(2026, 4, 18),
      );
      expect(log.oldData, isNull);
      expect(log.newData, isNotNull);
      expect(log.changeType, 'create');
    });

    test('delete type log mein newData null hona chahiye', () {
      final log = ProductAuditLog(
        id: 'log-delete', productId: 'prod-001',
        userName: 'M Hashim', changeType: 'delete',
        oldData: {'name': 'Pepsi', 'quantity': '4.0'},
        newData: null,
        changedAt: DateTime(2026, 4, 10),
      );
      expect(log.newData, isNull);
      expect(log.oldData, isNotNull);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 2: WarehouseStockInventory.fromJson
  // ══════════════════════════════════════════════════════════
  group('WarehouseStockInventory.fromJson —', () {

    Map<String, dynamic> baseJson() => {
      'id':             '0b88b44b-2c8e-4be7-8bff-b32876fd0784', // ✅ UUID String
      'product_name':   'Suger',
      'sku':            'JG-64268749',
      'barcode':        '0731811817180',
      'name':           'Suger',
      'description':    '',
      'category':       'Grocery',
      'unit':           'kg',
      'sell_price':     200.0,
      'purchase_price': 180.0,
      'whole_price':    190.0,
      'tax':            0.0,
      'discount':       0.0,
      'min_stock':      30,
      'max_stock':      100,
      'company_name':   'Jan Ghani',
      'expiry_date':    null,
      'is_active':      true,
      'created_at':     '2026-04-16T11:23:53.000',
      'updated_at':     '2026-04-18T14:43:17.000',
    };

    test('valid JSON se sahi parse ho', () {
      final model = WarehouseStockInventory.fromJson(baseJson());

      expect(model.id,            '0b88b44b-2c8e-4be7-8bff-b32876fd0784'); // ✅ String
      expect(model.sku,           'JG-64268749');
      expect(model.name,          'Suger');
      expect(model.sellPrice,     200.0);
      expect(model.purchasePrice, 180.0);
      expect(model.wholePrice,    190.0);
      expect(model.isActive,      true);
      expect(model.expiryDate,    isNull);
    });

    test('expiry_date present hone pe parse ho', () {
      final json = baseJson()
        ..['expiry_date'] = '2027-01-01T00:00:00.000';
      final model = WarehouseStockInventory.fromJson(json);
      expect(model.expiryDate, isNotNull);
      expect(model.expiryDate!.year, 2027);
    });

    test('expiry_date null hone pe null rahe', () {
      final model = WarehouseStockInventory.fromJson(baseJson());
      expect(model.expiryDate, isNull);
    });

    // ── Known issues — yeh tests fail honge aur fix ki zaroorat hai ──
    group('⚠️  NULL SAFETY ISSUES (fix zaroor karo) —', () {

      test('null id pe crash nahi hona chahiye [CURRENTLY FAILS]', () {
        // Yeh test fail karta hai kyunki fromJson mein null check nahi
        // FIX: id: json['id'] ?? 0
        final json = baseJson()..['id'] = null;
        expect(
              () => WarehouseStockInventory.fromJson(json),
          returnsNormally,    // abhi yeh fail hoga
        );
      });

      test('null sell_price pe crash nahi hona chahiye [CURRENTLY FAILS]', () {
        // FIX: sellPrice: (json['sell_price'] as num? ?? 0).toDouble()
        final json = baseJson()..['sell_price'] = null;
        expect(
              () => WarehouseStockInventory.fromJson(json),
          returnsNormally,
        );
      });
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 3: WarehouseStockInventory.toJson
  // ══════════════════════════════════════════════════════════
  group('WarehouseStockInventory.toJson —', () {

    test('toJson → fromJson roundtrip sahi kaam kare', () {
      final original = WarehouseStockInventory(
        id:            '2976e056-387a-4132-89c4-b17fa79c0010', // ✅ UUID
        productName:   'Dal',
        sku:           'JG-43574695',
        barcode:       '4329531886430',
        name:          'Dal',
        description:   '',
        category:      'Grocery',
        unit:          'kg',
        sellPrice:     200.0,
        purchasePrice: 140.0,
        wholePrice:    160.0,
        tax:           0.0,
        discount:      0.0,
        minStock:      20,
        maxStock:      50,
        companyName:   'Jan Ghani',
        expiryDate:    null,
        isActive:      true,
        createdAt:     DateTime(2026, 4, 18),
        updatedAt:     DateTime(2026, 4, 18),
      );

      final json         = original.toJson();
      final fromJsonBack = WarehouseStockInventory.fromJson(json);

      expect(fromJsonBack.id,            original.id);
      expect(fromJsonBack.sku,           original.sku);
      expect(fromJsonBack.sellPrice,     original.sellPrice);
      expect(fromJsonBack.purchasePrice, original.purchasePrice);
      expect(fromJsonBack.isActive,      original.isActive);
      expect(fromJsonBack.expiryDate,    isNull);
    });

    test('toJson mein expiry_date ISO string format mein ho', () {
      final expiry = DateTime(2027, 6, 15);
      final model  = WarehouseStockInventory(
        id: 'exp-001', productName: 'X', sku: 'X', barcode: 'X', name: 'X', // ✅
        description: '', category: '', unit: 'pcs',
        sellPrice: 0, purchasePrice: 0, wholePrice: 0,
        tax: 0, discount: 0, minStock: 0, maxStock: 0,
        companyName: '', expiryDate: expiry, isActive: true,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );

      final json = model.toJson();
      expect(json['expiry_date'], isNotNull);
      expect(json['expiry_date'], contains('2027-06-15'));
    });

    test('toJson null expiry_date → null in json', () {
      final model = WarehouseStockInventory(
        id: 'exp-002', productName: 'X', sku: 'X', barcode: 'X', name: 'X', // ✅
        description: '', category: '', unit: 'pcs',
        sellPrice: 0, purchasePrice: 0, wholePrice: 0,
        tax: 0, discount: 0, minStock: 0, maxStock: 0,
        companyName: '', expiryDate: null, isActive: true,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(model.toJson()['expiry_date'], isNull);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 4: Business Logic Checks
  // ══════════════════════════════════════════════════════════
  group('Business logic —', () {

    test('sell_price purchasePrice se zyada honi chahiye (margin check)', () {
      final model = WarehouseStockInventory(
        id: '39751335-7e52-4ac0-af7b-febab2a750fc', // ✅ UUID
        productName: 'Kingtox', sku: 'JG-21677155',
        barcode: '7137571699364', name: 'Kingtox',
        description: '', category: 'testing', unit: 'pcs',
        sellPrice: 120.0, purchasePrice: 100.0, wholePrice: 0,
        tax: 0, discount: 0, minStock: 30, maxStock: 100,
        companyName: 'Jan Ghani', isActive: true,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(model.sellPrice > model.purchasePrice, true);
    });

    test('inactive product isActive false hona chahiye', () {
      final model = WarehouseStockInventory(
        id: 'old-prod-uuid-001', // ✅ UUID style String
        productName: 'Old Product', sku: 'OLD-001',
        barcode: '', name: 'Old', description: '', category: '',
        unit: 'pcs', sellPrice: 0, purchasePrice: 0, wholePrice: 0,
        tax: 0, discount: 0, minStock: 0, maxStock: 0,
        companyName: '', isActive: false,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(model.isActive, false);
    });
  });
}