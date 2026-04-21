// =============================================================
// product_model_real_data_test.dart
// Tests using ACTUAL database values from warehouse_products table
// Yeh tests real production data se match karte hain
// Run: flutter test test/features/warehouse/warehouse_stock_inventory/product_model_real_data_test.dart
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';

void main() {

  // ══════════════════════════════════════════════════════════
  // Real DB rows — exact values jo DB mein hain
  // ══════════════════════════════════════════════════════════

  // Row 1: Pepsi (deleted — deleted_at set hai)
  final mapPepsi = {
    'id':              'f5edee6a-0bf9-470d-a5b5-69c6a5fb8c82',
    'warehouse_id':    'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'sku':             'JG-878365',
    'barcode':         '{8759373854}',           // postgres string format
    'name':            'Pepsi',
    'description':     'Pepsi 1.5 liter',
    'category_id':     'cf7f9ed4-e61d-4f22-b353-a641902537f7',
    'category_name':   'Cool drinks',
    'unit_of_measure': 'pcs',
    'purchase_price':  100.00,
    'selling_price':   120.00,
    'wholesale_price': 110.00,
    'tax_rate':        0.00,
    'min_stock_level': 30,
    'max_stock_level': 100,
    'reorder_point':   0,
    'is_active':       true,
    'is_track_stock':  true,
    'created_at':      '2026-04-10 12:26:32.072094+05',
    'updated_at':      '2026-04-18 12:08:45.706257+05',
    'deleted_at':      '2026-04-10 13:52:31.372703+05',  // ← deleted hai
    'quantity':        0.0,
    'reserved_quantity': 0.0,
  };

  // Row 2: Mong Pali (no description, no wholesale, no deleted_at)
  final mapMongPali = {
    'id':              '5b1a94b8-d7ac-4624-a4a8-6c005d4631c6',
    'warehouse_id':    'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'sku':             'JG-95557433',
    'barcode':         '{9310975655695,7133220397780,4640926327223}', // 3 barcodes
    'name':            'Mong Pali',
    'description':     null,                     // ← empty/null
    'category_id':     '8d6f8eca-e732-45e7-a4b1-eeff2a7cc23f',
    'category_name':   'Grocery',
    'unit_of_measure': 'kg',
    'purchase_price':  200.00,
    'selling_price':   240.00,
    'wholesale_price': null,                     // ← null wholesale
    'tax_rate':        0.00,
    'min_stock_level': 10,
    'max_stock_level': 30,
    'reorder_point':   0,
    'is_active':       true,
    'is_track_stock':  true,
    'created_at':      '2026-04-16 21:39:07.935547+05',
    'updated_at':      '2026-04-18 12:08:45.706257+05',
    'deleted_at':      null,
    'quantity':        100.0,
    'reserved_quantity': 0.0,
  };

  // Row 3: Kingtox (no description, no wholesale)
  final mapKingtox = {
    'id':              '39751335-7e52-4ac0-af7b-febab2a750fc',
    'warehouse_id':    'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'sku':             'JG-21677155',
    'barcode':         '{7137571699364}',
    'name':            'Kingtox',
    'description':     null,
    'category_id':     'ad322919-1fb2-4a99-ad9c-85500d2411d4',
    'category_name':   'testing',
    'unit_of_measure': 'pcs',
    'purchase_price':  100.00,
    'selling_price':   120.00,
    'wholesale_price': null,
    'tax_rate':        0.00,
    'min_stock_level': 30,
    'max_stock_level': 100,
    'reorder_point':   0,
    'is_active':       true,
    'is_track_stock':  true,
    'created_at':      '2026-04-17 18:05:05.764892+05',
    'updated_at':      '2026-04-18 12:08:45.706257+05',
    'deleted_at':      null,
    'quantity':        60.0,
    'reserved_quantity': 0.0,
  };

  // Row 4: Pepsi 1 liter (reorderPoint = 40, active product)
  final mapPepsi1L = {
    'id':              '3108e176-f0f1-492e-abbf-fc3fcbfce71b',
    'warehouse_id':    'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'sku':             'Jg-8397434',
    'barcode':         '{897422342}',
    'name':            'Pepsi 1 liter',
    'description':     '1 liter',
    'category_id':     'cf7f9ed4-e61d-4f22-b353-a641902537f7',
    'category_name':   'Cool drinks',
    'unit_of_measure': 'pcs',
    'purchase_price':  122.00,
    'selling_price':   145.00,
    'wholesale_price': 130.00,
    'tax_rate':        0.00,
    'min_stock_level': 30,
    'max_stock_level': 100,
    'reorder_point':   40,
    'is_active':       true,
    'is_track_stock':  true,
    'created_at':      '2026-04-10 13:53:15.3604+05',
    'updated_at':      '2026-04-18 14:36:46.632727+05',
    'deleted_at':      null,
    'quantity':        36.0,
    'reserved_quantity': 0.0,
  };

  // Row 5: Sugar (4 barcodes)
  final mapSugar = {
    'id':              '0b88b44b-2c8e-4be7-8bff-b32876fd0784',
    'warehouse_id':    'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'sku':             'JG-64268749',
    'barcode':         '{0731811817180,6115126632715,6127530860240,890347896478945}',
    'name':            'Suger',
    'description':     null,
    'category_id':     '8d6f8eca-e732-45e7-a4b1-eeff2a7cc23f',
    'category_name':   'Grocery',
    'unit_of_measure': 'kg',
    'purchase_price':  180.00,
    'selling_price':   200.00,
    'wholesale_price': 190.00,
    'tax_rate':        0.00,
    'min_stock_level': 30,
    'max_stock_level': 100,
    'reorder_point':   0,
    'is_active':       true,
    'is_track_stock':  true,
    'created_at':      '2026-04-16 11:23:53.523502+05',
    'updated_at':      '2026-04-18 14:43:17.212967+05',
    'deleted_at':      null,
    'quantity':        35.0,
    'reserved_quantity': 0.0,
  };

  // Row 6: Dal (reorderPoint = 30 — yeh low stock hai!)
  final mapDal = {
    'id':              '2976e056-387a-4132-89c4-b17fa79c0010',
    'warehouse_id':    'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'sku':             'JG-43574695',
    'barcode':         '{4329531886430}',
    'name':            'Dal',
    'description':     null,
    'category_id':     '8d6f8eca-e732-45e7-a4b1-eeff2a7cc23f',
    'category_name':   'Grocery',
    'unit_of_measure': 'kg',
    'purchase_price':  140.00,
    'selling_price':   200.00,
    'wholesale_price': 160.00,
    'tax_rate':        0.00,
    'min_stock_level': 20,
    'max_stock_level': 50,
    'reorder_point':   30,
    'is_active':       true,
    'is_track_stock':  true,
    'created_at':      '2026-04-18 17:29:46.311616+05',
    'updated_at':      '2026-04-18 17:30:31.610737+05',
    'deleted_at':      null,
    'quantity':        25.0,
    'reserved_quantity': 0.0,
  };

  // Row 7: Family 1Kg (purchase_price = 301.67 — decimal)
  final mapFamily = {
    'id':              '5eb20e03-ffd0-4385-9d57-b40bbe8aa446',
    'warehouse_id':    'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'sku':             'jg-8923473',             // ← lowercase sku
    'barcode':         '{8972633334}',
    'name':            'Family 1Kg',
    'description':     '1 Kg',
    'category_id':     '53de1729-7c93-43eb-ad49-73bdccbbb5a3',
    'category_name':   'Banasapti',
    'unit_of_measure': 'kg',
    'purchase_price':  301.67,                   // ← decimal price
    'selling_price':   350.00,
    'wholesale_price': 312.00,
    'tax_rate':        0.00,
    'min_stock_level': 20,
    'max_stock_level': 41,
    'reorder_point':   0,
    'is_active':       true,
    'is_track_stock':  true,
    'created_at':      '2026-04-10 12:52:29.414906+05',
    'updated_at':      '2026-04-18 21:46:28.910333+05',
    'deleted_at':      null,
    'quantity':        30.0,
    'reserved_quantity': 0.0,
  };

  // Row 8: Shama Banasapti 5Kg (highest price product)
  final mapShama = {
    'id':              '7d58c0f1-40f3-481a-b932-9d002eb4b407',
    'warehouse_id':    'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'sku':             'Jg-8934783',
    'barcode':         '{8728944}',
    'name':            'Shama Banasapti 5Kg',
    'description':     '5kg',
    'category_id':     '53de1729-7c93-43eb-ad49-73bdccbbb5a3',
    'category_name':   'Banasapti',
    'unit_of_measure': 'kg',
    'purchase_price':  4098.00,
    'selling_price':   4620.00,
    'wholesale_price': 4200.00,
    'tax_rate':        0.00,
    'min_stock_level': 10,
    'max_stock_level': 20,
    'reorder_point':   15,
    'is_active':       true,
    'is_track_stock':  true,
    'created_at':      '2026-04-10 12:33:11.199465+05',
    'updated_at':      '2026-04-18 21:46:28.914741+05',
    'deleted_at':      null,
    'quantity':        60.0,
    'reserved_quantity': 0.0,
  };

  // ══════════════════════════════════════════════════════════
  // GROUP 1: Har product sahi parse hona chahiye
  // ══════════════════════════════════════════════════════════
  group('Real DB data — fromMap parsing —', () {

    test('Pepsi (deleted product) sahi parse ho', () {
      final p = ProductModel.fromMap(mapPepsi);
      expect(p.id,            'f5edee6a-0bf9-470d-a5b5-69c6a5fb8c82');
      expect(p.sku,           'JG-878365');
      expect(p.name,          'Pepsi');
      expect(p.barcodes,      ['8759373854']);
      expect(p.purchasePrice, 100.0);
      expect(p.sellingPrice,  120.0);
      expect(p.wholesalePrice,110.0);
      expect(p.deletedAt,     isNotNull);  // deleted hai
      expect(p.categoryName,  'Cool drinks');
    });

    test('Mong Pali — 3 barcodes, null wholesale, null description', () {
      final p = ProductModel.fromMap(mapMongPali);
      expect(p.name,           'Mong Pali');
      expect(p.barcodes.length, 3);
      expect(p.barcodes, containsAll([
        '9310975655695', '7133220397780', '4640926327223'
      ]));
      expect(p.wholesalePrice, isNull);
      expect(p.description,    isNull);
      expect(p.unitOfMeasure,  'kg');
    });

    test('Sugar — 4 barcodes sahi parse hon', () {
      final p = ProductModel.fromMap(mapSugar);
      expect(p.barcodes.length, 4);
      expect(p.barcodes.first, '0731811817180');
      expect(p.barcodes.last,  '890347896478945');
      expect(p.name,           'Suger');
      expect(p.quantity,       35.0);
    });

    test('Family 1Kg — decimal purchase_price 301.67 sahi parse ho', () {
      final p = ProductModel.fromMap(mapFamily);
      expect(p.purchasePrice, 301.67);
      expect(p.sku,           'jg-8923473');  // lowercase preserve ho
      expect(p.categoryName,  'Banasapti');
    });

    test('Shama Banasapti — high price product sahi parse ho', () {
      final p = ProductModel.fromMap(mapShama);
      expect(p.purchasePrice, 4098.00);
      expect(p.sellingPrice,  4620.00);
      expect(p.wholesalePrice,4200.00);
      expect(p.maxStockLevel, 20);
      expect(p.reorderPoint,  15);
    });

    test('Pepsi 1 liter — reorderPoint = 40 sahi ho', () {
      final p = ProductModel.fromMap(mapPepsi1L);
      expect(p.reorderPoint,   40);
      expect(p.minStockLevel,  30);
      expect(p.quantity,       36.0);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 2: Business Logic — real data se
  // ══════════════════════════════════════════════════════════
  group('Business logic — real data —', () {

    test('Dal reorder chahiye — qty(25) <= reorderPoint(30)', () {
      final dal = ProductModel.fromMap(mapDal);
      expect(dal.needsReorder, true);   // 25 <= 30
      expect(dal.isLowStock,   false);  // 25 > 20 (minStock)
    });

    test('Pepsi 1 liter — reorder chahiye — qty(36) <= reorderPoint(40)', () {
      final p = ProductModel.fromMap(mapPepsi1L);
      expect(p.needsReorder, true);   // 36 <= 40
      expect(p.isLowStock,   false);  // 36 > 30
    });

    test('Shama Banasapti — reorder nahi chahiye — qty(60) > reorderPoint(15)', () {
      final p = ProductModel.fromMap(mapShama);
      expect(p.needsReorder, false);  // 60 > 15
      expect(p.isLowStock,   false);  // 60 > 10
    });

    test('Mong Pali — bilkul theek — qty(100) kaafi zyada', () {
      final p = ProductModel.fromMap(mapMongPali);
      expect(p.needsReorder, false);  // reorderPoint=0 → no reorder configured
      expect(p.isLowStock,   false);  // 100 > 10
    });

    // ✅ NEW — reorderPoint=0 wale products
    test('Sugar — reorderPoint=0 → needsReorder=false chahe stock kam ho', () {
      final p = ProductModel.fromMap(mapSugar);
      expect(p.reorderPoint,  0);
      expect(p.needsReorder,  false); // 0 matlab reorder configure nahi kiya
    });

    test('Kingtox — reorderPoint=0 → needsReorder=false', () {
      final p = ProductModel.fromMap(mapKingtox);
      expect(p.reorderPoint,  0);
      expect(p.needsReorder,  false);
    });

    test('Pepsi (deleted) — availableQty = 0', () {
      final p = ProductModel.fromMap(mapPepsi);
      expect(p.availableQty, 0.0);    // qty=0, reserved=0
    });

    test('Selling price > purchase price (profit margin) — sab products', () {
      for (final m in [mapMongPali, mapKingtox, mapPepsi1L,
        mapSugar, mapDal, mapFamily, mapShama]) {
        final p = ProductModel.fromMap(m);
        expect(p.sellingPrice > p.purchasePrice, true,
            reason: '${p.name}: sell(${p.sellingPrice}) > buy(${p.purchasePrice})');
      }
    });

    test('Wholesale price between purchase and selling — jahan wholesale hai', () {
      // Pepsi 1 liter: buy=122, wholesale=130, sell=145
      final p = ProductModel.fromMap(mapPepsi1L);
      expect(p.wholesalePrice! > p.purchasePrice,  true);
      expect(p.wholesalePrice! < p.sellingPrice,   true);

      // Shama: buy=4098, wholesale=4200, sell=4620
      final s = ProductModel.fromMap(mapShama);
      expect(s.wholesalePrice! > s.purchasePrice,  true);
      expect(s.wholesalePrice! < s.sellingPrice,   true);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 3: Deleted product filter
  // ══════════════════════════════════════════════════════════
  group('Deleted product behavior —', () {

    test('Pepsi deletedAt set hai — filter mein nahi aana chahiye', () {
      final pepsi = ProductModel.fromMap(mapPepsi);
      expect(pepsi.deletedAt, isNotNull);

      // Simulate filteredProducts logic
      final allProducts = [
        pepsi,
        ProductModel.fromMap(mapPepsi1L),
        ProductModel.fromMap(mapMongPali),
      ];

      final visible = allProducts
          .where((p) => p.deletedAt == null)
          .toList();

      expect(visible.length, 2);
      expect(visible.any((p) => p.id == pepsi.id), false);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 4: Barcode search — real barcodes se
  // ══════════════════════════════════════════════════════════
  group('Barcode search — real data —', () {

    final allProducts = <ProductModel>[];

    setUp(() {
      allProducts.addAll([
        ProductModel.fromMap(mapPepsi1L),
        ProductModel.fromMap(mapSugar),
        ProductModel.fromMap(mapMongPali),
        ProductModel.fromMap(mapFamily),
        ProductModel.fromMap(mapShama),
        ProductModel.fromMap(mapDal),
        ProductModel.fromMap(mapKingtox),
      ]);
    });

    test('Sugar barcode "0731811817180" se dhundhna', () {
      final found = allProducts.where((p) =>
          p.barcodes.contains('0731811817180')).toList();
      expect(found.length, 1);
      expect(found.first.name, 'Suger');
    });

    test('Mong Pali ka 2nd barcode "7133220397780" se dhundhna', () {
      final found = allProducts.where((p) =>
          p.barcodes.contains('7133220397780')).toList();
      // Mong Pali zaroor hona chahiye results mein
      expect(found.any((p) => p.name == 'Mong Pali'), true);
    });

    test('Partial barcode search (prefix "897") — Pepsi 1L milna chahiye', () {
      const query = '897';
      final found = allProducts.where((p) =>
          p.barcodes.any((b) => b.contains(query))).toList();
      expect(found.any((p) => p.name == 'Pepsi 1 liter'), true);
    });

    test('Non-existent barcode → empty result', () {
      final found = allProducts.where((p) =>
          p.barcodes.contains('9999999999')).toList();
      expect(found, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 5: PrimaryBarcode
  // ══════════════════════════════════════════════════════════
  group('primaryBarcode — real data —', () {

    test('Sugar primaryBarcode → first barcode', () {
      final p = ProductModel.fromMap(mapSugar);
      expect(p.primaryBarcode, '0731811817180');
    });

    test('Kingtox primaryBarcode → single barcode', () {
      final p = ProductModel.fromMap(mapKingtox);
      expect(p.primaryBarcode, '7137571699364');
    });

    test('Mong Pali primaryBarcode → first of 3', () {
      final p = ProductModel.fromMap(mapMongPali);
      expect(p.primaryBarcode, '9310975655695');
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 6: copyWith — real product update
  // ══════════════════════════════════════════════════════════
  group('copyWith — real update scenarios —', () {

    test('Shama price update — jab supplier ne price badla', () {
      final original = ProductModel.fromMap(mapShama);
      // Audit log mein: purchase_price 4097.74 → 4098.00
      final updated = original.copyWith(purchasePrice: 4098.00);

      expect(updated.purchasePrice, 4098.00);
      expect(updated.sellingPrice,  original.sellingPrice); // same rahe
      expect(updated.id,            original.id);
    });

    test('Family 1Kg maxStock update — 40 → 41', () {
      final original = ProductModel.fromMap(mapFamily);
      // Audit log mein: max_stock 40 → 41
      final updated = original.copyWith(maxStockLevel: 41);

      expect(updated.maxStockLevel, 41);
      expect(updated.minStockLevel, original.minStockLevel);
    });

    test('Soft delete — deletedAt set karna', () {
      final original = ProductModel.fromMap(mapPepsi1L);
      expect(original.deletedAt, isNull);

      final deleted = original.copyWith(deletedAt: DateTime(2026, 4, 10, 13, 52));
      expect(deleted.deletedAt,  isNotNull);
      expect(deleted.name,       original.name); // name change nahi hua
    });
  });
}