// =============================================================
// product_provider_test.dart
// UPDATED: TestableProductNotifier hataya — seedha ProductNotifier
//          inject karo (dependency injection fix ke baad)
// =============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/datasource/product_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';

@GenerateMocks([ProductRemoteDataSource])
import 'product_provider_test.mocks.dart';

// ── Test helper ───────────────────────────────────────────────
ProductModel makeProd({
  String id             = 'prod-001',
  String sku            = 'JG-1234',
  String name           = 'Pepsi 1 liter',
  List<String> barcodes = const ['897422342'],
  double purchasePrice  = 120.0,
  double sellingPrice   = 145.0,
  double quantity       = 50.0,
  int minStockLevel     = 30,
  int reorderPoint      = 40,
  bool isActive         = true,
  DateTime? deletedAt,
}) {
  return ProductModel(
    id:            id,
    warehouseId:   'wh-001',
    sku:           sku,
    barcodes:      barcodes,
    name:          name,
    unitOfMeasure: 'pcs',
    purchasePrice: purchasePrice,
    sellingPrice:  sellingPrice,
    taxRate:       0.0,
    minStockLevel: minStockLevel,
    reorderPoint:  reorderPoint,
    isActive:      isActive,
    isTrackStock:  true,
    createdAt:     DateTime(2026, 4, 10),
    updatedAt:     DateTime(2026, 4, 18),
    deletedAt:     deletedAt,
    quantity:      quantity,
  );
}

// ✅ Extension — test mein state seedha set karo
// Ab TestableProductNotifier ki zaroorat nahi
extension NotifierTestHelper on ProductNotifier {
  void loadTestProducts(List<ProductModel> products) {
    state = state.copyWith(allProducts: products, isLoading: false);
  }
}

void main() {
  late MockProductRemoteDataSource mockDs;
  late ProductNotifier notifier;

  // ✅ AppConfig ek baar load karo — config.json ka real data
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // ✅ SharedPreferences mock — AuthLocalStorage ke liye
    const MethodChannel channel =
    MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, dynamic>{};
      return null;
    });

    // ✅ config.json mock — AppConfig ke liye
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'assets/json/config.json') {
        const config = '{'
            '"app_mode": "warehouse",'
            '"warehouse_id": "c519975f-bf0e-4747-b152-ea38fcbf7cc5",'
            '"warehouse_code": "JG-WH-001",'
            '"warehouse_name": "Jan Ghani Warehouse 001",'
            '"db_host": "localhost",'
            '"db_port": 5432,'
            '"db_name": "warehouse_db",'
            '"db_user": "warehouseuser",'
            '"db_password": "warehouseUser123"'
            '}';
        return ByteData.view(Uint8List.fromList(utf8.encode(config)).buffer);
      }
      return null;
    });
    await AppConfig.load();
  });

  setUp(() {
    mockDs   = MockProductRemoteDataSource();
    // ✅ AppConfig.warehouseId — config.json se aata hai, hardcoded nahi
    notifier = ProductNotifier(mockDs, AppConfig.warehouseId);
  });

  tearDown(() => notifier.dispose());

  group('Initial state —', () {
    test('shuru mein empty list hona chahiye', () {
      expect(notifier.state.allProducts,  isEmpty);
      expect(notifier.state.isLoading,    false);
      expect(notifier.state.errorMessage, isNull);
    });
  });

  group('addProduct —', () {

    test('naya product successfully add ho', () async {
      final savedProduct = makeProd(id: 'prod-new', sku: 'JG-NEW');
      when(mockDs.skuExists(any, any)).thenAnswer((_) async => false);
      when(mockDs.add(
        product: anyNamed('product'), initialQty: anyNamed('initialQty'),
        userId: anyNamed('userId'),   userName: anyNamed('userName'),
      )).thenAnswer((_) async => savedProduct);

      await notifier.addProduct(
        sku: 'JG-NEW', name: 'New Product', unitOfMeasure: 'pcs',
        purchasePrice: 100.0, sellingPrice: 120.0,
        taxRate: 0.0, minStockLevel: 10, reorderPoint: 5,
        isActive: true, isTrackStock: true, initialQty: 20.0,
      );

      expect(notifier.state.allProducts.length,   1);
      expect(notifier.state.allProducts.first.id, 'prod-new');
      expect(notifier.state.isLoading,            false);
      expect(notifier.state.errorMessage,         isNull);
    });

    test('duplicate SKU pe error aana chahiye', () async {
      when(mockDs.skuExists('DUPLICATE-SKU', any)).thenAnswer((_) async => true);

      await notifier.addProduct(
        sku: 'DUPLICATE-SKU', name: 'Some Product', unitOfMeasure: 'pcs',
        purchasePrice: 100.0, sellingPrice: 120.0,
        taxRate: 0.0, minStockLevel: 10, reorderPoint: 5,
        isActive: true, isTrackStock: true, initialQty: 0.0,
      );

      expect(notifier.state.errorMessage, contains('DUPLICATE-SKU'));
      expect(notifier.state.allProducts,  isEmpty);
      verifyNever(mockDs.add(
        product: anyNamed('product'), initialQty: anyNamed('initialQty'),
        userId: anyNamed('userId'),   userName: anyNamed('userName'),
      ));
    });

    test('database error pe errorMessage set ho', () async {
      when(mockDs.skuExists(any, any)).thenAnswer((_) async => false);
      when(mockDs.add(
        product: anyNamed('product'), initialQty: anyNamed('initialQty'),
        userId: anyNamed('userId'),   userName: anyNamed('userName'),
      )).thenThrow(Exception('DB connection failed'));

      await notifier.addProduct(
        sku: 'JG-ERR', name: 'Error Product', unitOfMeasure: 'pcs',
        purchasePrice: 100.0, sellingPrice: 120.0,
        taxRate: 0.0, minStockLevel: 10, reorderPoint: 5,
        isActive: true, isTrackStock: true, initialQty: 0.0,
      );

      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.isLoading,    false);
    });
  });

  group('updateProduct —', () {

    setUp(() => notifier.loadTestProducts([
      makeProd(id: 'prod-001', sku: 'JG-1234', sellingPrice: 120.0),
    ]));

    test('product successfully update ho', () async {
      final updated     = makeProd(id: 'prod-001', sku: 'JG-1234', sellingPrice: 145.0);
      final freshFromDb = makeProd(id: 'prod-001', sku: 'JG-1234', sellingPrice: 145.0);

      when(mockDs.skuExists('JG-1234', any, excludeId: 'prod-001'))
          .thenAnswer((_) async => false);
      when(mockDs.update(
        oldProduct: anyNamed('oldProduct'), newProduct: anyNamed('newProduct'),
        newQty: anyNamed('newQty'), userId: anyNamed('userId'),
        userName: anyNamed('userName'),
      )).thenAnswer((_) async => freshFromDb);

      await notifier.updateProduct(updated);

      expect(notifier.state.allProducts
          .firstWhere((p) => p.id == 'prod-001').sellingPrice, 145.0);
      expect(notifier.state.isLoading, false);
    });

    test('update mein duplicate SKU -> error', () async {
      when(mockDs.skuExists('EXISTING-SKU', any, excludeId: 'prod-001'))
          .thenAnswer((_) async => true);
      await notifier.updateProduct(makeProd(id: 'prod-001', sku: 'EXISTING-SKU'));
      expect(notifier.state.errorMessage, contains('EXISTING-SKU'));
    });
  });

  group('deleteProduct —', () {

    setUp(() => notifier.loadTestProducts([
      makeProd(id: 'prod-001'),
      makeProd(id: 'prod-002', name: 'Family 1Kg'),
    ]));

    test('product soft delete ho — deletedAt set ho', () async {
      when(mockDs.delete(
        id: 'prod-001', product: anyNamed('product'),
        userId: anyNamed('userId'), userName: anyNamed('userName'),
      )).thenAnswer((_) async {});

      await notifier.deleteProduct('prod-001');

      expect(notifier.state.allProducts
          .firstWhere((p) => p.id == 'prod-001').deletedAt, isNotNull);
      expect(notifier.state.allProducts
          .firstWhere((p) => p.id == 'prod-002').deletedAt, isNull);
    });

    test('delete error pe errorMessage set ho', () async {
      when(mockDs.delete(
        id: anyNamed('id'), product: anyNamed('product'),
        userId: anyNamed('userId'), userName: anyNamed('userName'),
      )).thenThrow(Exception('Delete failed'));

      await notifier.deleteProduct('prod-001');

      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.isLoading,    false);
    });
  });

  group('Filters aur Search —', () {

    setUp(() => notifier.loadTestProducts([
      makeProd(id: '1', name: 'Pepsi 1 liter', sku: 'JG-001',
          barcodes: ['897422342'], isActive: true),
      makeProd(id: '2', name: 'Family 1Kg', sku: 'JG-002',
          barcodes: ['8972633334'], isActive: true),
      makeProd(id: '3', name: 'Shama Banasapti', sku: 'JG-003',
          barcodes: ['8728944'], isActive: false),
    ]));

    test('search query update ho', () {
      notifier.onSearchChanged('pepsi');
      expect(notifier.state.searchQuery, 'pepsi');
    });

    test('filter status active pe sirf active products', () {
      notifier.onFilterStatusChanged('active');
      expect(notifier.state.filteredProducts.every((p) => p.isActive), true);
    });

    test('search empty karne pe sab products wapas', () {
      notifier.onSearchChanged('pepsi');
      notifier.onSearchChanged('');
      expect(notifier.state.filteredProducts.length, 3);
    });

    test('clearError ke baad errorMessage null ho', () async {
      when(mockDs.skuExists(any, any)).thenAnswer((_) async => true);
      await notifier.addProduct(
        sku: 'X', name: 'X', unitOfMeasure: 'pcs',
        purchasePrice: 1, sellingPrice: 1, taxRate: 0,
        minStockLevel: 0, reorderPoint: 0,
        isActive: true, isTrackStock: true, initialQty: 0,
      );
      expect(notifier.state.errorMessage, isNotNull);
      notifier.clearError();
      expect(notifier.state.errorMessage, isNull);
    });
  });

  group('Count getters —', () {
    test('totalCount, activeCount, lowStockCount sahi hona chahiye', () {
      notifier.loadTestProducts([
        makeProd(id: '1', isActive: true,  quantity: 5,  minStockLevel: 30),
        makeProd(id: '2', isActive: true,  quantity: 50, minStockLevel: 30),
        makeProd(id: '3', isActive: false, quantity: 10, minStockLevel: 30),
        makeProd(id: '4', isActive: true,  quantity: 20, deletedAt: DateTime.now()),
      ]);
      expect(notifier.state.totalCount,    3);
      expect(notifier.state.activeCount,   2);
      expect(notifier.state.lowStockCount, 2);
    });
  });
}