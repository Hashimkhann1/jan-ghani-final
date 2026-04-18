// // =============================================================
// // supplier_dummy_data.dart
// // Sirf development/testing ke liye dummy data
// // TODO: Jab Drift DB ready ho to yeh file delete karo
// //       aur SupplierNotifier mein real DB call lagao
// // =============================================================
//
// import 'package:jan_ghani_final/features/supplier/domian/supplier_model.dart';
//
// /// Dummy suppliers list — warehouse schema ke saath match karta hai
// /// suppliers table + v_supplier_balances view + purchase_orders aggregate
// final List<SupplierModel> supplierDummyData = [
//   SupplierModel(
//     id:                  'sup-001',
//     // tenantId:            'tenant-jan-ghani',
//     name:                'Ahmed Raza',
//     companyName:         'Raza Traders',
//     contactPerson:       'Ahmed Raza',
//     email:               'ahmed@razatraders.pk',
//     phone:               '03001234567',
//     address:             'Hall Road, Lahore',
//     code:                'SUPP-0001',
//     taxId:               'NTN-12345',
//     paymentTerms:        30,               // 30 din credit
//     isActive:            true,
//     notes:               'Main grocery supplier',
//     createdAt:           DateTime(2025, 1, 10),
//     updatedAt:           DateTime(2026, 3, 1),
//     outstandingBalance:  12000,            // hum ne dena hai → Due
//     totalOrders:         24,
//     totalPurchaseAmount: 450000,
//   ),
//
//   SupplierModel(
//     id:                  'sup-002',
//     tenantId:            'tenant-jan-ghani',
//     name:                'Bilal Khan',
//     companyName:         'Khan Brothers',
//     contactPerson:       'Bilal Khan',
//     email:               'bilal@khanbros.pk',
//     phone:               '03111234567',
//     address:             'Saddar, Karachi',
//     code:                'SUPP-0002',
//     taxId:               null,
//     paymentTerms:        15,               // 15 din credit
//     isActive:            true,
//     notes:               null,
//     createdAt:           DateTime(2025, 3, 20),
//     updatedAt:           DateTime(2026, 2, 15),
//     outstandingBalance:  0,                // bilkul clear
//     totalOrders:         18,
//     totalPurchaseAmount: 320000,
//   ),
//
//   SupplierModel(
//     id:                  'sup-003',
//     tenantId:            'tenant-jan-ghani',
//     name:                'Tariq Mehmood',
//     companyName:         'TM Distributors',
//     contactPerson:       'Tariq Mehmood',
//     email:               null,
//     phone:               '03211234567',
//     address:             'F-7, Islamabad',
//     code:                'SUPP-0003',
//     taxId:               'NTN-67890',
//     paymentTerms:        45,               // 45 din credit
//     isActive:            false,            // inactive supplier
//     notes:               'Seasonal supplier — garmion mein active hota hai',
//     createdAt:           DateTime(2024, 11, 5),
//     updatedAt:           DateTime(2025, 12, 10),
//     outstandingBalance:  0,
//     totalOrders:         6,
//     totalPurchaseAmount: 180000,
//   ),
//
//   SupplierModel(
//     id:                  'sup-004',
//     tenantId:            'tenant-jan-ghani',
//     name:                'Kamran Iqbal',
//     companyName:         'Iqbal & Sons',
//     contactPerson:       'Kamran Iqbal',
//     email:               'kamran@iqbalsons.pk',
//     phone:               '03321234567',
//     address:             'Qissa Khwani Bazaar, Peshawar',
//     code:                'SUPP-0004',
//     taxId:               null,
//     paymentTerms:        30,
//     isActive:            true,
//     notes:               null,
//     createdAt:           DateTime(2025, 6, 14),
//     updatedAt:           DateTime(2026, 3, 20),
//     outstandingBalance:  8500,             // hum ne dena hai → Due
//     totalOrders:         10,
//     totalPurchaseAmount: 95000,
//   ),
//
//   SupplierModel(
//     id:                  'sup-005',
//     tenantId:            'tenant-jan-ghani',
//     name:                'Usman Farooq',
//     companyName:         'Farooq Wholesale',
//     contactPerson:       'Usman Farooq',
//     email:               'usman@farooqwholesale.pk',
//     phone:               '03431234567',
//     address:             'Hussain Agahi, Multan',
//     code:                'SUPP-0005',
//     taxId:               'NTN-11223',
//     paymentTerms:        60,               // 60 din credit — bada supplier
//     isActive:            true,
//     notes:               'Sab se bada supplier — special rates milti hain',
//     createdAt:           DateTime(2024, 9, 1),
//     updatedAt:           DateTime(2026, 3, 28),
//     outstandingBalance:  35000,            // hum ne dena hai → Due
//     totalOrders:         42,
//     totalPurchaseAmount: 620000,
//   ),
//
//   SupplierModel(
//     id:                  'sup-006',
//     tenantId:            'tenant-jan-ghani',
//     name:                'Zubair Ahmed',
//     companyName:         'ZA Traders',
//     contactPerson:       'Zubair Ahmed',
//     email:               null,
//     phone:               '03551234567',
//     address:             'Kachehri Road, Faisalabad',
//     code:                'SUPP-0006',
//     taxId:               null,
//     paymentTerms:        30,
//     isActive:            true,
//     notes:               null,
//     createdAt:           DateTime(2025, 8, 22),
//     updatedAt:           DateTime(2026, 1, 18),
//     outstandingBalance:  0,                // bilkul clear
//     totalOrders:         15,
//     totalPurchaseAmount: 240000,
//   ),
// ];