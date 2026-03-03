


import 'package:jan_ghani_final/model/customer_model/customer_model.dart';
import 'package:jan_ghani_final/model/product_model/product_model.dart';
import 'package:jan_ghani_final/model/purchase_order_model.dart';
import 'package:jan_ghani_final/model/warehouse_model/warehouse_model.dart';
import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';
import 'package:jan_ghani_final/utils/dialogs/customer_dialogs/customer_detail_dialogs.dart';
import 'package:jan_ghani_final/view/customers_view/customers_view.dart';

class DummyData {

  // Inventory Product Dummy data
  static const List<ProductModel> inventoryProducts = [
    ProductModel(
      name: 'Coke',
      sku: 'ctp',
      category: 'Beverages',
      stock: 0,
      minStock: 10,
      value: 27500,
      status: StockStatus.outOfStock,
      variants: 3,
      initials: 'C',
    ),
    ProductModel(
      name: 'DBR Growth Boosting Oil',
      sku: 'DBR-9W18RL',
      category: 'DBR',
      stock: 18,
      minStock: 10,
      value: 27000,
      status: StockStatus.inStock,
      initials: 'D',
    ),
    ProductModel(
      name: 'DBR Herbal Soap',
      sku: 'DBR-NFPU7C',
      category: 'DBR',
      stock: 14233,
      minStock: 10,
      value: 8539800,
      status: StockStatus.overstock,
      initials: 'D',
    ),
    ProductModel(
      name: 'DBR Whitening Cream',
      sku: 'DBR-DQLZD8',
      category: 'DBR',
      stock: 349,
      minStock: 10,
      value: 523500,
      status: StockStatus.overstock,
      initials: 'D',
    ),
    ProductModel(
      name: 'DBR Zuni Seerum',
      sku: 'DBR-TWGMKH',
      category: 'DBR',
      stock: 30759,
      minStock: 10,
      value: 21531300,
      status: StockStatus.overstock,
      initials: 'D',
    ),
    ProductModel(
      name: 'safeguard',
      sku: 'SAF-VSLFB0',
      category: 'Unilever',
      stock: 1007,
      minStock: 10,
      value: 100700,
      status: StockStatus.overstock,
      initials: 'S',
    ),
    ProductModel(
      name: 'Shampoo',
      sku: 'SHA-MWVDFF',
      category: 'Unilever',
      stock: 3596,
      minStock: 10,
      value: 359600,
      status: StockStatus.overstock,
      initials: 'S',
    ),
    ProductModel(
      name: 'Sprite 240ml Regular',
      sku: '086',
      category: 'Beverages',
      stock: 29,
      minStock: 10,
      value: 1305,
      status: StockStatus.inStock,
      initials: 'S',
    ),
    ProductModel(
      name: 'Pepsi 500ml',
      sku: 'PEP-500ML',
      category: 'Beverages',
      stock: 5,
      minStock: 20,
      value: 12500,
      status: StockStatus.lowStock,
      initials: 'P',
    ),
    ProductModel(
      name: 'Lays Classic Salted',
      sku: 'LAY-CLS-01',
      category: 'Snacks',
      stock: 0,
      minStock: 15,
      value: 8900,
      status: StockStatus.outOfStock,
      initials: 'L',
    ),
    ProductModel(
      name: 'Lifebuoy Hand Wash',
      sku: 'LBY-HW-200',
      category: 'Unilever',
      stock: 842,
      minStock: 10,
      value: 421000,
      status: StockStatus.overstock,
      initials: 'L',
    ),
    ProductModel(
      name: 'Nestle Milk Pack 1L',
      sku: 'NES-MLK-1L',
      category: 'Dairy',
      stock: 74,
      minStock: 30,
      value: 185000,
      status: StockStatus.inStock,
      initials: 'N',
    ),
    ProductModel(
      name: 'Colgate Total 120g',
      sku: 'COL-TOT-120',
      category: 'Oral Care',
      stock: 3,
      minStock: 25,
      value: 3600,
      status: StockStatus.lowStock,
      initials: 'C',
    ),
    ProductModel(
      name: 'Surf Excel 500g',
      sku: 'SRF-EXL-500',
      category: 'Unilever',
      stock: 2210,
      minStock: 10,
      value: 3094000,
      status: StockStatus.overstock,
      initials: 'S',
    ),
  ];

  // Customer Dummy data
  static List<CustomerModel> dummyCustomers = [
    CustomerModel(
      id: '1',
      name: 'Asad Mukhtar',
      email: 'asad0002332@gmail.com',
      phone: '+9211111111111',
      creditLimit: 5000,
      balance: 0,
      totalPurchases: 4500,
      points: 0,
      address: 'House No. 15, Gulberg III, Lahore',
      notes: 'Preferred customer. Pays via credit.',
      totalOrders: 2,
      customerSince: DateTime(2026, 2, 1),
      orders: [
        CustomerOrder(
          orderId: 'MAIN-20260225-0004',
          date: DateTime(2026, 2, 25),
          paymentMethod: 'Credit',
          amount: 3000,
          status: 'completed',
        ),
        CustomerOrder(
          orderId: 'MAIN-20260225-0003',
          date: DateTime(2026, 2, 25),
          paymentMethod: 'Credit',
          amount: 1500,
          status: 'completed',
        ),
      ],
    ),
    CustomerModel(
      id: '2',
      name: 'Sara Khan',
      email: 'sara.khan@gmail.com',
      phone: '+923001234567',
      creditLimit: 10000,
      balance: 1500,
      totalPurchases: 12000,
      points: 240,
      address: 'Flat 4B, Block 7, Clifton, Karachi',
      notes: 'Bulk buyer. Usually orders on weekends.',
      totalOrders: 5,
      customerSince: DateTime(2025, 10, 15),
      orders: [
        CustomerOrder(
          orderId: 'MAIN-20260210-0011',
          date: DateTime(2026, 2, 10),
          paymentMethod: 'Cash',
          amount: 4500,
          status: 'completed',
        ),
        CustomerOrder(
          orderId: 'MAIN-20260115-0008',
          date: DateTime(2026, 1, 15),
          paymentMethod: 'Credit',
          amount: 3200,
          status: 'completed',
        ),
        CustomerOrder(
          orderId: 'MAIN-20251220-0005',
          date: DateTime(2025, 12, 20),
          paymentMethod: 'Credit',
          amount: 4300,
          status: 'completed',
        ),
      ],
    ),
    CustomerModel(
      id: '3',
      name: 'Muhammad Ali',
      email: 'mali@yahoo.com',
      phone: '+923451234567',
      creditLimit: 15000,
      balance: 10000,
      totalPurchases: 12000,
      points: 175,
      address: 'Street 9, G-10/2, Islamabad',
      notes: '',
      totalOrders: 4,
      customerSince: DateTime(2025, 8, 3),
      orders: [
        CustomerOrder(
          orderId: 'MAIN-20260201-0015',
          date: DateTime(2026, 2, 1),
          paymentMethod: 'Cash',
          amount: 2750,
          status: 'completed',
        ),
        CustomerOrder(
          orderId: 'MAIN-20260110-0009',
          date: DateTime(2026, 1, 10),
          paymentMethod: 'Cash',
          amount: 3000,
          status: 'completed',
        ),
        CustomerOrder(
          orderId: 'MAIN-20251105-0003',
          date: DateTime(2025, 11, 5),
          paymentMethod: 'Cash',
          amount: 3000,
          status: 'completed',
        ),
      ],
    ),
    CustomerModel(
      id: '5',
      name: 'Usman Tariq',
      email: 'usman.tariq@gmail.com',
      phone: '+923121234567',
      creditLimit: 8000,
      balance: 800,
      totalPurchases: 19500,
      points: 390,
      address: 'House 7, Johar Town, Lahore',
      notes: 'Regular monthly buyer. Prefers evening delivery.',
      totalOrders: 7,
      customerSince: DateTime(2025, 3, 11),
      orders: [
        CustomerOrder(
          orderId: 'MAIN-20260215-0017',
          date: DateTime(2026, 2, 15),
          paymentMethod: 'Credit',
          amount: 4200,
          status: 'completed',
        ),
        CustomerOrder(
          orderId: 'MAIN-20260120-0010',
          date: DateTime(2026, 1, 20),
          paymentMethod: 'Cash',
          amount: 3800,
          status: 'completed',
        ),
        CustomerOrder(
          orderId: 'MAIN-20251130-0006',
          date: DateTime(2025, 11, 30),
          paymentMethod: 'Credit',
          amount: 3100,
          status: 'cancelled',
        ),
      ],
    ),
  ];


// ── Suppliers ──────────────────────────────────────────────────────────────

  static final PoSupplierModel _asadMukhtar = PoSupplierModel(
    id: 1,
    name: 'Asad Mukhtar',
    contactPerson: 'Asad Mukhtar',
    email: 'asad@gmail.com',
    phone: '+923001234567',
    address: 'Lahore, Pakistan',
    paymentTerms: 30,
    createdAt: DateTime(2026, 1, 1),
  );

  static final PoSupplierModel _makkahTraders = PoSupplierModel(
    id: 2,
    name: 'Makkah Traders',
    contactPerson: 'Ali Naeem',
    email: 'ali@makkahtraders.com',
    phone: '+923011234567',
    address: 'Karachi, Pakistan',
    paymentTerms: 15,
    createdAt: DateTime(2026, 1, 5),
  );

  static final PoSupplierModel _ali = PoSupplierModel(
    id: 3,
    name: 'ali',
    contactPerson: '45122521',
    email: '',
    phone: '45122521',
    address: '',
    paymentTerms: 30,
    createdAt: DateTime(2026, 1, 10),
  );

  // ── Purchase Orders ────────────────────────────────────────────────────────

  static final List<PurchaseOrderModel> dummyPurchaseOrders = [
    PurchaseOrderModel(
      id: 1,
      poNumber: 'PO-eee-20260228-0002',
      supplier: _asadMukhtar,
      destinationLocationName: 'eee',
      status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 28),
      expectedDate: DateTime(2026, 2, 28),
      receivedDate: DateTime(2026, 2, 28),
      subtotal: 50000,
      totalAmount: 50000,
      items: [
        PurchaseOrderItem(id: 1, poId: 1, productName: 'DBR Herbal Soap',
            quantityOrdered: 10, quantityReceived: 10, unitCost: 5000, totalCost: 50000),
      ],
    ),
    PurchaseOrderModel(
      id: 2,
      poNumber: 'PO-WH-20260228-0002',
      supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse',
      status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 28),
      expectedDate: DateTime(2026, 2, 28),
      receivedDate: DateTime(2026, 2, 28),
      subtotal: 7200000,
      totalAmount: 7200000,
      items: [
        PurchaseOrderItem(id: 2, poId: 2, productName: 'DBR Zuni Seerum',
            quantityOrdered: 4800, quantityReceived: 4800, unitCost: 1500, totalCost: 7200000),
      ],
    ),
    PurchaseOrderModel(
      id: 3,
      poNumber: 'PO-WH-20260228-0001',
      supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse',
      status: PurchaseOrderStatus.ordered,
      orderDate: DateTime(2026, 2, 28),
      expectedDate: DateTime(2026, 2, 28),
      subtotal: 2400000,
      totalAmount: 2400000,
      items: [
        PurchaseOrderItem(id: 3, poId: 3, productName: 'DBR Whitening Cream',
            quantityOrdered: 800, quantityReceived: 0, unitCost: 3000, totalCost: 2400000),
      ],
    ),
    PurchaseOrderModel(
      id: 4,
      poNumber: 'PO-eee-20260228-0001',
      supplier: _asadMukhtar,
      destinationLocationName: 'eee',
      status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 28),
      expectedDate: DateTime(2026, 2, 28),
      receivedDate: DateTime(2026, 2, 28),
      subtotal: 2000000,
      totalAmount: 2000000,
      items: [
        PurchaseOrderItem(id: 4, poId: 4, productName: 'DBR Growth Boosting Oil',
            quantityOrdered: 400, quantityReceived: 400, unitCost: 5000, totalCost: 2000000),
      ],
    ),
    PurchaseOrderModel(
      id: 5,
      poNumber: 'PO-eee-20260227-0001',
      supplier: _asadMukhtar,
      destinationLocationName: 'eee',
      status: PurchaseOrderStatus.ordered,
      orderDate: DateTime(2026, 2, 27),
      expectedDate: DateTime(2026, 2, 28),
      subtotal: 120,
      totalAmount: 120,
      items: [
        PurchaseOrderItem(id: 5, poId: 5, productName: 'Coke',
            quantityOrdered: 2, quantityReceived: 0, unitCost: 60, totalCost: 120),
      ],
    ),
    PurchaseOrderModel(
      id: 6, poNumber: 'PO-WH-20260224-0012', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 45000000, totalAmount: 45000000,
      items: [PurchaseOrderItem(id: 6, poId: 6, productName: 'DBR Zuni Seerum',
          quantityOrdered: 30000, quantityReceived: 30000, unitCost: 1500, totalCost: 45000000)],
    ),
    PurchaseOrderModel(
      id: 7, poNumber: 'PO-MAIN-20260224-0011', supplier: _asadMukhtar,
      destinationLocationName: 'Main Store', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 750000, totalAmount: 750000,
      items: [PurchaseOrderItem(id: 7, poId: 7, productName: 'Shampoo',
          quantityOrdered: 2500, quantityReceived: 2500, unitCost: 300, totalCost: 750000)],
    ),
    PurchaseOrderModel(
      id: 8, poNumber: 'PO-MAIN-20260224-0010', supplier: _asadMukhtar,
      destinationLocationName: 'Main Store', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 300000, totalAmount: 300000,
      items: [PurchaseOrderItem(id: 8, poId: 8, productName: 'safeguard',
          quantityOrdered: 2500, quantityReceived: 2500, unitCost: 120, totalCost: 300000)],
    ),
    PurchaseOrderModel(
      id: 9, poNumber: 'PO-WH-20260224-0009', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 180000000, totalAmount: 180000000,
      items: [PurchaseOrderItem(id: 9, poId: 9, productName: 'DBR Zuni Seerum',
          quantityOrdered: 120000, quantityReceived: 120000, unitCost: 1500, totalCost: 180000000)],
    ),
    PurchaseOrderModel(
      id: 10, poNumber: 'PO-WH-20260224-0008', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 100000000, totalAmount: 100000000,
    ),
    PurchaseOrderModel(
      id: 11, poNumber: 'PO-WH-20260224-0007', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 20998600, totalAmount: 20998600,
    ),
    PurchaseOrderModel(
      id: 12, poNumber: 'PO-WH-20260224-0006', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 30000000, totalAmount: 30000000,
    ),
    PurchaseOrderModel(
      id: 13, poNumber: 'PO-WH-20260224-0005', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 150000000, totalAmount: 150000000,
    ),
    PurchaseOrderModel(
      id: 14, poNumber: 'PO-WH-20260224-0004', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 10000000, totalAmount: 10000000,
    ),
    PurchaseOrderModel(
      id: 15, poNumber: 'PO-WH-20260224-0003', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 3600000, totalAmount: 3600000,
    ),
    PurchaseOrderModel(
      id: 16, poNumber: 'PO-WH-20260224-0002', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 75000000, totalAmount: 75000000,
    ),
    PurchaseOrderModel(
      id: 17, poNumber: 'PO-WH-20260224-0001', supplier: _asadMukhtar,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 24), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 24), subtotal: 5600000, totalAmount: 5600000,
    ),
    PurchaseOrderModel(
      id: 18, poNumber: 'PO-WH-20260223-0001', supplier: _makkahTraders,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 23), expectedDate: DateTime(2026, 2, 24),
      receivedDate: DateTime(2026, 2, 23), subtotal: 10500000, totalAmount: 10500000,
    ),
    PurchaseOrderModel(
      id: 19, poNumber: 'PO-MAIN-20260221-0001', supplier: _makkahTraders,
      destinationLocationName: 'Main Store', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 21), expectedDate: DateTime(2026, 2, 21),
      receivedDate: DateTime(2026, 2, 21), subtotal: 350000, totalAmount: 350000,
    ),
    PurchaseOrderModel(
      id: 20, poNumber: 'PO-WH-20260220-0002', supplier: _ali,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 20), expectedDate: DateTime(2026, 2, 20),
      receivedDate: DateTime(2026, 2, 20), subtotal: 15000000, totalAmount: 15000000,
    ),
    PurchaseOrderModel(
      id: 21, poNumber: 'PO-WH-20260220-0001', supplier: _makkahTraders,
      destinationLocationName: 'Warehouse', status: PurchaseOrderStatus.received,
      orderDate: DateTime(2026, 2, 20), expectedDate: DateTime(2026, 2, 20),
      receivedDate: DateTime(2026, 2, 20), subtotal: 140800, totalAmount: 140800,
    ),
  ];

  // --- Warehouse dummy data ────────────────────────────────────────────────────────

  static final List<WarehouseModel> dummyWarehouses = [
    WarehouseModel(
      id: 1,
      name: 'Testin Warehouse',
      code: '00123',
      address: 'Charsaada Sardhari',
      phone: '0313000000',
      productCount: 0,
      unitCount: 0,
      lowStockCount: 0,
    ),

    WarehouseModel(
      id: 2,
      name: 'Main Warehouse',
      code: '00876',
      address: 'Main Address tested',
      phone: '0313000000',
      productCount: 0,
      unitCount: 0,
      lowStockCount: 0,
    ),
  ];

// ─────────────────────────────────────────────────────────────────────────────
// ADD THESE STATIC MEMBERS to your existing DummyData class
// Also add these imports at the top of dummy_data.dart:
//   import 'package:jan_ghani_final/model/purchase_order_model.dart';
// ─────────────────────────────────────────────────────────────────────────────

  // ── Locations (maps to `locations` SQL table) ─────────────────────────────
  static final List<LocationModel> dummyLocations = [
    LocationModel(
      id: 1,
      code: 'WH-MAIN',
      name: 'Main Warehouse',
      type: LocationType.warehouse,
      address: 'Charsaada Road, Peshawar',
      phone: '0313000000',
      createdAt: DateTime(2026, 1, 1),
    ),
    LocationModel(
      id: 2,
      code: 'STORE-01',
      name: 'Main Store',
      type: LocationType.store,
      address: 'Saddar Bazaar, Peshawar',
      phone: '0312000001',
      createdAt: DateTime(2026, 1, 1),
    ),
    LocationModel(
      id: 3,
      code: 'eee',
      name: 'eee',
      type: LocationType.store,
      address: 'Test Branch',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  // ── PO Suppliers ──────────────────────────────────────────────────────────
  static final List<PoSupplierModel> dummyPoSuppliers = [
    PoSupplierModel(
      id: 1,
      name: 'Asad Mukhtar',
      contactPerson: 'Asad Mukhtar',
      email: 'asad@gmail.com',
      phone: '+923001234567',
      address: 'Lahore, Pakistan',
      paymentTerms: 30,
      createdAt: DateTime(2026, 1, 1),
    ),
    PoSupplierModel(
      id: 2,
      name: 'Makkah Traders',
      contactPerson: 'Ali Naeem',
      email: 'ali@makkahtraders.com',
      phone: '+923011234567',
      address: 'Karachi, Pakistan',
      paymentTerms: 15,
      createdAt: DateTime(2026, 1, 5),
    ),
    PoSupplierModel(
      id: 3,
      name: 'ali',
      contactPerson: '45122521',
      email: '',
      phone: '45122521',
      paymentTerms: 30,
      createdAt: DateTime(2026, 1, 10),
    ),
  ];

  // ── PO Products (PoProductSnapshot — for product selection in PlaceOrder) ─
  static const List<PoProductSnapshot> dummyPoProducts = [
    PoProductSnapshot(
      id: 1,
      sku: 'ctp',
      name: 'Coke',
      unitOfMeasure: 'pcs',
      costPrice: 60,
      categoryName: 'Beverages',
    ),
    PoProductSnapshot(
      id: 2,
      sku: 'DBR-9W18RL',
      name: 'DBR Growth Boosting Oil',
      unitOfMeasure: 'pcs',
      costPrice: 2500,
      categoryName: 'DBR',
    ),
    PoProductSnapshot(
      id: 3,
      sku: 'DBR-NFPU7C',
      name: 'DBR Herbal Soap',
      unitOfMeasure: 'pcs',
      costPrice: 1200,
      categoryName: 'DBR',
    ),
    PoProductSnapshot(
      id: 4,
      sku: 'DBR-DQLZD8',
      name: 'DBR Whitening Cream',
      unitOfMeasure: 'pcs',
      costPrice: 2800,
      categoryName: 'DBR',
    ),
    PoProductSnapshot(
      id: 5,
      sku: 'DBR-TWGMKH',
      name: 'DBR Zuni Seerum',
      unitOfMeasure: 'pcs',
      costPrice: 1300,
      categoryName: 'DBR',
    ),
    PoProductSnapshot(
      id: 6,
      sku: 'SAF-VSLFB0',
      name: 'safeguard',
      unitOfMeasure: 'pcs',
      costPrice: 100,
      categoryName: 'Unilever',
    ),
    PoProductSnapshot(
      id: 7,
      sku: 'SHA-MWVDFF',
      name: 'Shampoo',
      unitOfMeasure: 'pcs',
      costPrice: 250,
      categoryName: 'Unilever',
    ),
    PoProductSnapshot(
      id: 8,
      sku: '086',
      name: 'Sprite 240ml Regular',
      unitOfMeasure: 'pcs',
      costPrice: 40,
      categoryName: 'Beverages',
    ),
    PoProductSnapshot(
      id: 9,
      sku: 'PEP-500ML',
      name: 'Pepsi 500ml',
      unitOfMeasure: 'pcs',
      costPrice: 55,
      categoryName: 'Beverages',
    ),
    PoProductSnapshot(
      id: 10,
      sku: 'NES-MLK-1L',
      name: 'Nestle Milk Pack 1L',
      unitOfMeasure: 'pcs',
      costPrice: 200,
      categoryName: 'Dairy',
    ),
  ];

// ─────────────────────────────────────────────────────────────────────────────
// Also update the existing dummyPurchaseOrders list entries to use the new
// PurchaseOrderModel signature — replace:
//   destinationLocation: 'Warehouse'     →  destinationLocationName: 'Warehouse'
//   destinationLocation: 'eee'           →  destinationLocationName: 'eee'
//   destinationLocation: 'Main Store'    →  destinationLocationName: 'Main Store'
// ─────────────────────────────────────────────────────────────────────────────

}