// =============================================================
// product_model_test.dart
// Tests for: ProductModel (fromMap, copyWith, helpers)
// Run: flutter test test/features/warehouse/warehouse_stock_inventory/product_model_test.dart
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';

// ── Helper: ek test product banana ───────────────────────────
ProductModel makeProduct({
  String id            = 'prod-001',
  String warehouseId   = 'wh-001',
  String sku           = 'JG-1234',
  List<String> barcodes = const ['897422342'],
  String name          = 'Pepsi 1 liter',
  String unitOfMeasure = 'pcs',
  double purchasePrice = 120.0,
  double sellingPrice  = 145.0,
  double? wholesalePrice,
  double taxRate       = 0.0,
  int minStockLevel    = 30,
  int? maxStockLevel   = 100,
  int reorderPoint     = 40,
  bool isActive        = true,
  bool isTrackStock    = true,
  double quantity      = 50.0,
  double reservedQty   = 5.0,
  DateTime? deletedAt,
}) {
  return ProductModel(
    id:            id,
    warehouseId:   warehouseId,
    sku:           sku,
    barcodes:      barcodes,
    name:          name,
    unitOfMeasure: unitOfMeasure,
    purchasePrice: purchasePrice,
    sellingPrice:  sellingPrice,
    wholesalePrice: wholesalePrice,
    taxRate:       taxRate,
    minStockLevel: minStockLevel,
    maxStockLevel: maxStockLevel,
    reorderPoint:  reorderPoint,
    isActive:      isActive,
    isTrackStock:  isTrackStock,
    createdAt:     DateTime(2026, 4, 10),
    updatedAt:     DateTime(2026, 4, 18),
    deletedAt:     deletedAt,
    quantity:      quantity,
    reservedQty:   reservedQty,
  );
}

void main() {
  // ══════════════════════════════════════════════════════════
  // GROUP 1: fromMap — database se data parse karna
  // ══════════════════════════════════════════════════════════
  group('ProductModel.fromMap —', () {

    test('normal map se sahi parse hona chahiye', () {
      final map = {
        'id':             'prod-001',
        'warehouse_id':   'wh-001',
        'sku':            'JG-1234',
        'barcode':        ['897422342', '123456789'],
        'name':           'Pepsi 1 liter',
        'description':    '1 liter bottle',
        'category_id':    'cat-001',
        'category_name':  'Cool drinks',
        'unit_of_measure':'pcs',
        'purchase_price': 120.0,
        'selling_price':  145.0,
        'wholesale_price':130.0,
        'tax_rate':       0.0,
        'min_stock_level':30,
        'max_stock_level':100,
        'reorder_point':  40,
        'is_active':      true,
        'is_track_stock': true,
        'created_at':     '2026-04-10T00:00:00.000',
        'updated_at':     '2026-04-18T00:00:00.000',
        'deleted_at':     null,
        'quantity':       50.0,
        'reserved_quantity': 5.0,
      };

      final product = ProductModel.fromMap(map);

      expect(product.id,            'prod-001');
      expect(product.sku,           'JG-1234');
      expect(product.name,          'Pepsi 1 liter');
      expect(product.barcodes,      ['897422342', '123456789']);
      expect(product.purchasePrice, 120.0);
      expect(product.sellingPrice,  145.0);
      expect(product.wholesalePrice,130.0);
      expect(product.quantity,      50.0);
      expect(product.reservedQty,   5.0);
      expect(product.categoryName,  'Cool drinks');
      expect(product.isActive,      true);
      expect(product.deletedAt,     isNull);
    });

    // ── Barcode parsing ──────────────────────────────────────
    group('barcode parsing —', () {

      test('Dart List format sahi parse ho', () {
        final map = _baseMap()..['barcode'] = ['897422342', '123456'];
        final p = ProductModel.fromMap(map);
        expect(p.barcodes, ['897422342', '123456']);
      });

      test('Postgres string format {val1,val2} sahi parse ho', () {
        final map = _baseMap()..['barcode'] = '{897422342,123456}';
        final p = ProductModel.fromMap(map);
        expect(p.barcodes, ['897422342', '123456']);
      });

      test('Empty postgres string {} → empty list', () {
        final map = _baseMap()..['barcode'] = '{}';
        final p = ProductModel.fromMap(map);
        expect(p.barcodes, isEmpty);
      });

      test('null barcode → empty list', () {
        final map = _baseMap()..['barcode'] = null;
        final p = ProductModel.fromMap(map);
        expect(p.barcodes, isEmpty);
      });

      test('Single barcode string → list with one item', () {
        final map = _baseMap()..['barcode'] = '{8972633334}';
        final p = ProductModel.fromMap(map);
        expect(p.barcodes.length, 1);
        expect(p.barcodes.first,  '8972633334');
      });
    });

    // ── is_active parsing ────────────────────────────────────
    group('is_active parsing —', () {

      test("is_active = true (bool) → true", () {
        final map = _baseMap()..['is_active'] = true;
        expect(ProductModel.fromMap(map).isActive, true);
      });

      test("is_active = 't' (postgres string) → true", () {
        final map = _baseMap()..['is_active'] = 't';
        expect(ProductModel.fromMap(map).isActive, true);
      });

      test("is_active = false → false", () {
        final map = _baseMap()..['is_active'] = false;
        expect(ProductModel.fromMap(map).isActive, false);
      });
    });

    // ── Null / missing fields ────────────────────────────────
    group('null aur missing fields —', () {

      test('null purchase_price → 0.0', () {
        final map = _baseMap()..['purchase_price'] = null;
        expect(ProductModel.fromMap(map).purchasePrice, 0.0);
      });

      test('null wholesale_price → null (not 0)', () {
        final map = _baseMap()..['wholesale_price'] = null;
        expect(ProductModel.fromMap(map).wholesalePrice, isNull);
      });

      test('null quantity → 0.0', () {
        final map = _baseMap()..['quantity'] = null;
        expect(ProductModel.fromMap(map).quantity, 0.0);
      });

      test('price as String "120.50" → 120.50 double', () {
        final map = _baseMap()..['purchase_price'] = '120.50';
        expect(ProductModel.fromMap(map).purchasePrice, 120.50);
      });

      test('null deleted_at → null', () {
        final map = _baseMap()..['deleted_at'] = null;
        expect(ProductModel.fromMap(map).deletedAt, isNull);
      });
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 2: Computed properties
  // ══════════════════════════════════════════════════════════
  group('Computed properties —', () {

    test('availableQty = quantity - reservedQty', () {
      final p = makeProduct(quantity: 50, reservedQty: 5);
      expect(p.availableQty, 45.0);
    });

    test('availableQty = 0 jab quantity == reservedQty', () {
      final p = makeProduct(quantity: 10, reservedQty: 10);
      expect(p.availableQty, 0.0);
    });

    test('primaryBarcode → pehla barcode', () {
      final p = makeProduct(barcodes: ['first-code', 'second-code']);
      expect(p.primaryBarcode, 'first-code');
    });

    test('primaryBarcode → null jab barcodes empty', () {
      final p = makeProduct(barcodes: []);
      expect(p.primaryBarcode, isNull);
    });

    // ── isLowStock ───────────────────────────────────────────
    group('isLowStock —', () {

      test('true jab quantity <= minStockLevel aur isTrackStock = true', () {
        final p = makeProduct(quantity: 10, minStockLevel: 10, isTrackStock: true);
        expect(p.isLowStock, true);
      });

      test('true jab quantity minStockLevel se kam ho', () {
        final p = makeProduct(quantity: 5, minStockLevel: 10, isTrackStock: true);
        expect(p.isLowStock, true);
      });

      test('false jab quantity minStockLevel se zyada ho', () {
        final p = makeProduct(quantity: 50, minStockLevel: 10, isTrackStock: true);
        expect(p.isLowStock, false);
      });

      test('false jab isTrackStock = false (chahe stock kam ho)', () {
        final p = makeProduct(quantity: 2, minStockLevel: 30, isTrackStock: false);
        expect(p.isLowStock, false);
      });
    });

    // ── needsReorder ─────────────────────────────────────────
    group('needsReorder —', () {

      test('true jab quantity <= reorderPoint', () {
        final p = makeProduct(quantity: 40, reorderPoint: 40, isTrackStock: true);
        expect(p.needsReorder, true);
      });

      test('false jab quantity reorderPoint se zyada ho', () {
        final p = makeProduct(quantity: 60, reorderPoint: 40, isTrackStock: true);
        expect(p.needsReorder, false);
      });

      test('false jab isTrackStock = false', () {
        final p = makeProduct(quantity: 5, reorderPoint: 40, isTrackStock: false);
        expect(p.needsReorder, false);
      });

      // ✅ NEW — reorderPoint=0 fix
      test('false jab reorderPoint=0 — Sugar/Kingtox jaisi products', () {
        final p = makeProduct(quantity: 5, reorderPoint: 0, isTrackStock: true);
        expect(p.needsReorder, false); // 0 matlab no reorder configured
      });
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 3: copyWith
  // ══════════════════════════════════════════════════════════
  group('copyWith —', () {

    test('sirf diye gaye fields update hone chahiye', () {
      final original = makeProduct(name: 'Pepsi', sellingPrice: 120.0);
      final updated  = original.copyWith(sellingPrice: 145.0);

      expect(updated.sellingPrice, 145.0);
      expect(updated.name,         'Pepsi');  // change nahi hua
      expect(updated.id,           original.id);
    });

    test('barcodes update ho sakti hai', () {
      final original = makeProduct(barcodes: ['old-barcode']);
      final updated  = original.copyWith(barcodes: ['new-1', 'new-2']);

      expect(updated.barcodes, ['new-1', 'new-2']);
    });

    test('Soft delete — deletedAt set karna', () {
      final now      = DateTime.now();
      final original = makeProduct();
      final deleted  = original.copyWith(deletedAt: now);

      expect(deleted.deletedAt, now);
    });

    test('clearDeletedAt=true — deletedAt null ho jaye (restore product)', () {
      final deleted  = makeProduct(deletedAt: DateTime.now());
      expect(deleted.deletedAt, isNotNull);

      final restored = deleted.copyWith(clearDeletedAt: true);
      expect(restored.deletedAt, isNull);
    });

    test('warehouseId aur id kabhi nahi badalte', () {
      final original = makeProduct(id: 'prod-001', warehouseId: 'wh-001');
      final updated  = original.copyWith(name: 'New Name');

      expect(updated.id,          'prod-001');
      expect(updated.warehouseId, 'wh-001');
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 4: Equality
  // ══════════════════════════════════════════════════════════
  group('Equality —', () {

    test('same id = equal', () {
      final p1 = makeProduct(id: 'prod-001', name: 'Pepsi');
      final p2 = makeProduct(id: 'prod-001', name: 'Different Name');
      expect(p1, equals(p2));
    });

    test('alag id = not equal', () {
      final p1 = makeProduct(id: 'prod-001');
      final p2 = makeProduct(id: 'prod-002');
      expect(p1, isNot(equals(p2)));
    });
  });

  // ══════════════════════════════════════════════════════════
  // GROUP 5: ProductState filteredProducts
  // (Provider test ke baghair, sirf logic test)
  // ══════════════════════════════════════════════════════════
  group('ProductState.filteredProducts —', () {

    final products = [
      makeProduct(id: '1', name: 'Pepsi 1 liter', isActive: true,
          barcodes: ['897422342'], quantity: 50),
      makeProduct(id: '2', name: 'Family 1Kg', isActive: true,
          barcodes: ['8972633334'], quantity: 22),
      makeProduct(id: '3', name: 'Shama Banasapti', isActive: false,
          barcodes: ['8728944'], quantity: 5),
      makeProduct(id: '4', name: 'Deleted Product', isActive: true,
          deletedAt: DateTime.now()),
    ];

    ProductState stateWith({
      String search = '',
      String status = 'all',
      String category = 'all',
    }) {
      return ProductState(
        allProducts:    products,
        searchQuery:    search,
        filterStatus:   status,
        filterCategory: category,
      );
    }

    test('deleted products filter mein nahi aane chahiye', () {
      final filtered = stateWith().filteredProducts;
      expect(filtered.any((p) => p.id == '4'), false);
      expect(filtered.length, 3);
    });

    test('filterStatus = active sirf active products dikhaye', () {
      final filtered = stateWith(status: 'active').filteredProducts;
      expect(filtered.every((p) => p.isActive), true);
      expect(filtered.length, 2);
    });

    test('filterStatus = inactive sirf inactive products dikhaye', () {
      final filtered = stateWith(status: 'inactive').filteredProducts;
      expect(filtered.every((p) => !p.isActive), true);
      expect(filtered.length, 1);
    });

    test('search by name kaam kare', () {
      final filtered = stateWith(search: 'pepsi').filteredProducts;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Pepsi 1 liter');
    });

    test('search by barcode kaam kare', () {
      final filtered = stateWith(search: '8972633334').filteredProducts;
      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });

    test('search case-insensitive hona chahiye', () {
      final filtered = stateWith(search: 'PEPSI').filteredProducts;
      expect(filtered.isNotEmpty, true);
    });

    test('search no match → empty list', () {
      final filtered = stateWith(search: 'xyz-not-found').filteredProducts;
      expect(filtered, isEmpty);
    });
  });
}

// ── Base map helper ───────────────────────────────────────────
Map<String, dynamic> _baseMap() => {
  'id':              'prod-001',
  'warehouse_id':    'wh-001',
  'sku':             'JG-1234',
  'barcode':         ['897422342'],
  'name':            'Pepsi 1 liter',
  'description':     '1 liter',
  'category_id':     'cat-001',
  'category_name':   'Cool drinks',
  'unit_of_measure': 'pcs',
  'purchase_price':  120.0,
  'selling_price':   145.0,
  'wholesale_price': 130.0,
  'tax_rate':        0.0,
  'min_stock_level': 30,
  'max_stock_level': 100,
  'reorder_point':   40,
  'is_active':       true,
  'is_track_stock':  true,
  'created_at':      '2026-04-10T00:00:00.000',
  'updated_at':      '2026-04-18T00:00:00.000',
  'deleted_at':      null,
  'quantity':        50.0,
  'reserved_quantity': 5.0,
};

// ProductState copy — test ke liye yahan define karte hain
// (actual import apne project se karein)
class ProductState {
  final List<ProductModel> allProducts;
  final String searchQuery;
  final String filterStatus;
  final String filterCategory;

  const ProductState({
    this.allProducts    = const [],
    this.searchQuery    = '',
    this.filterStatus   = 'all',
    this.filterCategory = 'all',
  });

  List<ProductModel> get filteredProducts {
    return allProducts.where((p) {
      if (p.deletedAt != null)                                        return false;
      if (filterStatus   == 'active'   && !p.isActive)               return false;
      if (filterStatus   == 'inactive' &&  p.isActive)               return false;
      if (filterCategory != 'all' && p.categoryId != filterCategory) return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q)     ||
            p.barcodes.any((b) => b.toLowerCase().contains(q)) ||
            (p.categoryName?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }
}