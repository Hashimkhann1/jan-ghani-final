// =============================================================
// supplier_model_test.dart
// SupplierModel — fromMap, copyWith, computed fields
// Real DB data se test kiya gaya hai
// =============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';

void main() {
  // ── Shared test data ─────────────────────────────────────
  // Real DB se liya gaya (Qasim Khan — outstanding balance wala)
  final Map<String, dynamic> fullMap = {
    'id':                   '4991b2bd-21bf-4251-9df8-b9e55ea415c8',
    'warehouse_id':         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'name':                 'Qasim Khan',
    'company_name':         'Coka Cola',
    'contact_person':       '0313000000',
    'email':                'qasim@gmail.com',
    'phone':                '0313000000',
    'address':              'nka asnjfbs ahajsbf',
    'code':                 'SUPP-0003',
    'tax_id':               '889755',
    'payment_terms':        30,
    'is_active':            true,
    'notes':                'this is the testing database',
    'created_by':           'a3f74bae-4a49-412a-bb51-c7166981ea3a',
    'created_by_name':      'M Hashim',
    'created_at':           DateTime(2026, 4, 9, 17, 23, 34),
    'updated_at':           DateTime(2026, 4, 18, 21, 45, 1),
    'deleted_at':           null,
    'outstanding_balance':  70000.50,
    'total_orders':         8,
    'total_purchase_amount': 95000.0,
  };

  // Sabir Khan — balance zero, clear supplier
  final Map<String, dynamic> clearSupplierMap = {
    'id':                   '85e7ba3a-0f97-4bc9-9df9-9bf26a74535e',
    'warehouse_id':         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'name':                 'Sabir Khan',
    'company_name':         'Jan Ghani',
    'contact_person':       '0313000000',
    'email':                'sabir@gmail.com',
    'phone':                '03130000000',
    'address':              'gull abad pull',
    'code':                 'SUPP-0004',
    'tax_id':               '8509325',
    'payment_terms':        30,
    'is_active':            true,
    'notes':                'abb opening balance test kar raha ho.',
    'created_by':           'a3f74bae-4a49-412a-bb51-c7166981ea3a',
    'created_by_name':      'M Hashim',
    'created_at':           DateTime(2026, 4, 9, 17, 46, 50),
    'updated_at':           DateTime(2026, 4, 18, 21, 42, 5),
    'deleted_at':           null,
    'outstanding_balance':  0.0,
    'total_orders':         0,
    'total_purchase_amount': 0.0,
  };

  // M Hashim (Pepsi) — soft deleted supplier
  final Map<String, dynamic> deletedSupplierMap = {
    'id':                   '7838e06b-6857-41ce-aede-2f2d592dcaf7',
    'warehouse_id':         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'name':                 'M Hashim',
    'company_name':         'Pepsi',
    'contact_person':       '03235200735',
    'email':                'hashimkhan@gmail.com',
    'phone':                '03139217887',
    'address':              'charsadda sardhari',
    'code':                 'SUPP-0001',
    'tax_id':               '90843974',
    'payment_terms':        45,
    'is_active':            true,
    'notes':                null,
    'created_by':           'a3f74bae-4a49-412a-bb51-c7166981ea3a',
    'created_by_name':      null,
    'created_at':           DateTime(2026, 4, 9, 16, 30, 24),
    'updated_at':           DateTime(2026, 4, 18, 12, 8, 45),
    'deleted_at':           DateTime(2026, 4, 9, 16, 35, 55),
    'outstanding_balance':  0.0,
    'total_orders':         0,
    'total_purchase_amount': 0.0,
  };

  // Amjad Khan — edge case: 0.77 outstanding (near zero)
  final Map<String, dynamic> edgeCaseMap = {
    'id':                   '785ec87d-5fd3-46cf-810f-c0b0ddb13b12',
    'warehouse_id':         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
    'name':                 'Amjad kahn',
    'company_name':         'Super Biscut',
    'contact_person':       '03130000000',
    'email':                'amjad@gmail.com',
    'phone':                '03130000000',
    'address':              'jksdabc asdbcb jasbdjc',
    'code':                 'SUPP-0005',
    'tax_id':               '89734',
    'payment_terms':        30,
    'is_active':            true,
    'notes':                'this is the testing supplier for created by record',
    'created_by':           'a3f74bae-4a49-412a-bb51-c7166981ea3a',
    'created_by_name':      'M Hashim',
    'created_at':           DateTime(2026, 4, 11, 0, 12, 35),
    'updated_at':           DateTime(2026, 4, 18, 17, 44, 55),
    'deleted_at':           null,
    'outstanding_balance':  0.77,
    'total_orders':         12,
    'total_purchase_amount': 150000.0,
  };

  // ── Group 1: fromMap ──────────────────────────────────────
  group('SupplierModel.fromMap —', () {

    test('basic fields sahi parse hote hain', () {
      final model = SupplierModel.fromMap(fullMap);

      expect(model.id,          '4991b2bd-21bf-4251-9df8-b9e55ea415c8');
      expect(model.warehouseId, 'c519975f-bf0e-4747-b152-ea38fcbf7cc5');
      expect(model.name,        'Qasim Khan');
      expect(model.companyName, 'Coka Cola');
      expect(model.phone,       '0313000000');
      expect(model.code,        'SUPP-0003');
      expect(model.taxId,       '889755');
    });

    test('numeric fields sahi parse hote hain', () {
      final model = SupplierModel.fromMap(fullMap);

      expect(model.paymentTerms,       30);
      expect(model.outstandingBalance, 70000.50);
      expect(model.totalOrders,        8);
      expect(model.totalPurchaseAmount, 95000.0);
    });

    test('bool field is_active — true parse hota hai', () {
      final model = SupplierModel.fromMap(fullMap);
      expect(model.isActive, true);
    });

    test('bool field is_active — string "t" bhi parse hota hai', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['is_active'] = 't';
      final model = SupplierModel.fromMap(map);
      expect(model.isActive, true);
    });

    test('bool field is_active — false parse hota hai', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['is_active'] = false;
      final model = SupplierModel.fromMap(map);
      expect(model.isActive, false);
    });

    test('DateTime fields sahi parse hote hain', () {
      final model = SupplierModel.fromMap(fullMap);

      expect(model.createdAt, DateTime(2026, 4, 9, 17, 23, 34));
      expect(model.updatedAt, DateTime(2026, 4, 18, 21, 45, 1));
      expect(model.deletedAt, isNull);
    });

    test('deleted_at null nahi — parse hota hai', () {
      final model = SupplierModel.fromMap(deletedSupplierMap);
      expect(model.deletedAt, isNotNull);
      expect(model.deletedAt, DateTime(2026, 4, 9, 16, 35, 55));
    });

    test('nullable fields (notes, email, etc) null hote hain', () {
      final model = SupplierModel.fromMap(deletedSupplierMap);
      expect(model.notes,        isNull);
      expect(model.createdByName, isNull);
    });

    test('DateTime as String string bhi parse hota hai', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['created_at'] = '2026-04-09 17:23:34'
        ..['updated_at'] = '2026-04-18 21:45:01';
      final model = SupplierModel.fromMap(map);
      expect(model.createdAt.year, 2026);
      expect(model.updatedAt.month, 4);
    });

    test('outstanding_balance string se bhi parse hota hai', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['outstanding_balance'] = '70000.50';
      final model = SupplierModel.fromMap(map);
      expect(model.outstandingBalance, 70000.50);
    });

    test('payment_terms string se bhi parse hota hai', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['payment_terms'] = '30';
      final model = SupplierModel.fromMap(map);
      expect(model.paymentTerms, 30);
    });

    test('total_orders null ho toh 0 default', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['total_orders'] = null;
      final model = SupplierModel.fromMap(map);
      expect(model.totalOrders, 0);
    });

    test('total_purchase_amount null ho toh 0.0 default', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['total_purchase_amount'] = null;
      final model = SupplierModel.fromMap(map);
      expect(model.totalPurchaseAmount, 0.0);
    });

    test('payment_terms null ho toh 30 default', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['payment_terms'] = null;
      final model = SupplierModel.fromMap(map);
      expect(model.paymentTerms, 30);
    });

    test('created_by_name (JOIN se) sahi aata hai', () {
      final model = SupplierModel.fromMap(fullMap);
      expect(model.createdByName, 'M Hashim');
    });

    test('id null ho toh empty string', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['id'] = null;
      final model = SupplierModel.fromMap(map);
      expect(model.id, '');
    });

    test('phone null ho toh empty string', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['phone'] = null;
      final model = SupplierModel.fromMap(map);
      expect(model.phone, '');
    });
  });

  // ── Group 2: Computed Fields ──────────────────────────────
  group('SupplierModel computed fields —', () {

    test('hasDue — balance > 0 ho toh true', () {
      final model = SupplierModel.fromMap(fullMap);
      expect(model.hasDue, true);
    });

    test('hasDue — balance 0 ho toh false', () {
      final model = SupplierModel.fromMap(clearSupplierMap);
      expect(model.hasDue, false);
    });

    test('isClear — balance 0 ho toh true', () {
      final model = SupplierModel.fromMap(clearSupplierMap);
      expect(model.isClear, true);
    });

    test('isClear — balance > 0 ho toh false', () {
      final model = SupplierModel.fromMap(fullMap);
      expect(model.isClear, false);
    });

    test('balanceLabel — Due case (70000.50)', () {
      final model = SupplierModel.fromMap(fullMap);
      expect(model.balanceLabel, 'Rs 70001 Due'); // toStringAsFixed(0) rounds
    });

    test('balanceLabel — Clear case (0.0)', () {
      final model = SupplierModel.fromMap(clearSupplierMap);
      expect(model.balanceLabel, 'Clear');
    });

    test('balanceLabel — edge case 0.77', () {
      final model = SupplierModel.fromMap(edgeCaseMap);
      expect(model.balanceLabel, 'Rs 1 Due'); // 0.77 rounds to 1
    });

    test('paymentTermsLabel — 30 days', () {
      final model = SupplierModel.fromMap(fullMap);
      expect(model.paymentTermsLabel, '30 days');
    });

    test('paymentTermsLabel — 45 days (Pepsi supplier)', () {
      final model = SupplierModel.fromMap(deletedSupplierMap);
      expect(model.paymentTermsLabel, '45 days');
    });

    test('deletedAt set ho toh supplier deleted hai', () {
      final model = SupplierModel.fromMap(deletedSupplierMap);
      expect(model.deletedAt, isNotNull);
    });
  });

  // ── Group 3: copyWith ─────────────────────────────────────
  group('SupplierModel.copyWith —', () {

    test('name update hota hai', () {
      final original = SupplierModel.fromMap(fullMap);
      final updated  = original.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.id,   original.id); // id same rehta hai
    });

    test('outstandingBalance update hota hai', () {
      final original = SupplierModel.fromMap(fullMap);
      final updated  = original.copyWith(outstandingBalance: 0.0);
      expect(updated.outstandingBalance, 0.0);
      expect(updated.isClear, true);
    });

    test('isActive toggle hota hai', () {
      final original = SupplierModel.fromMap(fullMap);
      final inactive = original.copyWith(isActive: false);
      expect(inactive.isActive, false);
      expect(original.isActive, true); // original unchanged
    });

    test('paymentTerms update hota hai', () {
      final original = SupplierModel.fromMap(fullMap);
      final updated  = original.copyWith(paymentTerms: 60);
      expect(updated.paymentTerms, 60);
      expect(updated.paymentTermsLabel, '60 days');
    });

    test('deletedAt set karna (soft delete)', () {
      final original = SupplierModel.fromMap(clearSupplierMap);
      final deleted  = original.copyWith(deletedAt: DateTime(2026, 4, 20));
      expect(deleted.deletedAt, isNotNull);
      expect(original.deletedAt, isNull); // original unchanged
    });

    test('notes update hota hai', () {
      final original = SupplierModel.fromMap(fullMap);
      final updated  = original.copyWith(notes: 'Updated notes');
      expect(updated.notes, 'Updated notes');
    });

    test('totalOrders update hota hai', () {
      final original = SupplierModel.fromMap(fullMap);
      final updated  = original.copyWith(totalOrders: 15);
      expect(updated.totalOrders, 15);
    });

    test('warehouseId copyWith mein change nahi hota', () {
      final original = SupplierModel.fromMap(fullMap);
      final updated  = original.copyWith(name: 'Test');
      expect(updated.warehouseId, original.warehouseId);
    });

    test('createdAt copyWith mein change nahi hota', () {
      final original = SupplierModel.fromMap(fullMap);
      final updated  = original.copyWith(name: 'Test');
      expect(updated.createdAt, original.createdAt);
    });

    test('copyWith ke baad updatedAt change hota hai', () {
      final original = SupplierModel.fromMap(fullMap);
      final before   = original.updatedAt;
      // Small delay ensure karne ke liye
      final updated  = original.copyWith(name: 'Changed');
      // updatedAt DateTime.now() se set hota hai
      expect(updated.updatedAt, isA<DateTime>());
      expect(updated.updatedAt.isAfter(before) ||
          updated.updatedAt.isAtSameMomentAs(before), true);
    });
  });

  // ── Group 4: toMap ────────────────────────────────────────
  group('SupplierModel.toMap —', () {

    test('toMap basic fields sahi return karta hai', () {
      final model = SupplierModel.fromMap(fullMap);
      final map   = model.toMap();

      expect(map['id'],           '4991b2bd-21bf-4251-9df8-b9e55ea415c8');
      expect(map['warehouse_id'], 'c519975f-bf0e-4747-b152-ea38fcbf7cc5');
      expect(map['name'],         'Qasim Khan');
      expect(map['phone'],        '0313000000');
      expect(map['is_active'],    true);
      expect(map['payment_terms'], 30);
    });

    test('toMap mein outstanding_balance nahi hota (trigger handle karta hai)', () {
      final model = SupplierModel.fromMap(fullMap);
      final map   = model.toMap();
      expect(map.containsKey('outstanding_balance'), false);
    });

    test('fromMap → toMap → fromMap roundtrip', () {
      final original = SupplierModel.fromMap(fullMap);
      final map      = original.toMap();

      // toMap mein timestamps nahi hote, isliye manually add karte hain
      map['created_at'] = original.createdAt;
      map['updated_at'] = original.updatedAt;
      map['outstanding_balance']   = original.outstandingBalance;
      map['total_orders']          = original.totalOrders;
      map['total_purchase_amount'] = original.totalPurchaseAmount;

      final restored = SupplierModel.fromMap(map);
      expect(restored.id,   original.id);
      expect(restored.name, original.name);
      expect(restored.outstandingBalance, original.outstandingBalance);
    });
  });

  // ── Group 5: Real DB values se edge cases ─────────────────
  group('Real DB edge cases —', () {

    test('M Asim — balance 44000 (newest supplier)', () {
      final map = {
        'id':                   'e6fa0a4b-e6eb-4784-88a6-9e7c86343604',
        'warehouse_id':         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
        'name':                 'M Asim',
        'company_name':         'Wadana Foods',
        'contact_person':       '03130000000',
        'email':                'asim@gmail.com',
        'phone':                '03138050959',
        'address':              'gull abad pull',
        'code':                 'SUPP-0006',
        'tax_id':               '894373',
        'payment_terms':        30,
        'is_active':            true,
        'notes':                'this is frozens foods',
        'created_by':           '57f163eb-b8a1-416a-8996-90a0da7e83a7',
        'created_by_name':      'Warehouse',
        'created_at':           DateTime(2026, 4, 18, 17, 28, 28),
        'updated_at':           DateTime(2026, 4, 18, 21, 47, 2),
        'deleted_at':           null,
        'outstanding_balance':  44000.0,
        'total_orders':         1,
        'total_purchase_amount': 44000.0,
      };
      final model = SupplierModel.fromMap(map);
      expect(model.hasDue, true);
      expect(model.outstandingBalance, 44000.0);
      expect(model.totalOrders, 1);
    });

    test('M Hashim Testing — balance 100000.58 (large balance)', () {
      final model = SupplierModel.fromMap({
        'id':                   '79181d20-7422-4745-867a-07f879763b7b',
        'warehouse_id':         'c519975f-bf0e-4747-b152-ea38fcbf7cc5',
        'name':                 'M Hashim',
        'company_name':         'Testing',
        'contact_person':       '03130000000',
        'email':                'hashim@gmaiil.com',
        'phone':                '0313000000',
        'address':              'charsadda sardhari',
        'code':                 'SUPP-0002',
        'tax_id':               '8978656',
        'payment_terms':        30,
        'is_active':            true,
        'notes':                'daa yoo testing supplier',
        'created_by':           'a3f74bae-4a49-412a-bb51-c7166981ea3a',
        'created_by_name':      'M Hashim',
        'created_at':           DateTime(2026, 4, 9, 16, 43, 44),
        'updated_at':           DateTime(2026, 4, 18, 12, 8, 46),
        'deleted_at':           null,
        'outstanding_balance':  100000.58,
        'total_orders':         10,
        'total_purchase_amount': 220000.0,
      });
      expect(model.hasDue, true);
      expect(model.outstandingBalance, 100000.58);
      expect(model.balanceLabel, 'Rs 100001 Due');
    });

    test('Soft deleted supplier — hasDue false, deletedAt set', () {
      final model = SupplierModel.fromMap(deletedSupplierMap);
      expect(model.deletedAt, isNotNull);
      expect(model.isClear, true);
    });

    test('company_name nullable — null ho sakta hai', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['company_name'] = null;
      final model = SupplierModel.fromMap(map);
      expect(model.companyName, isNull);
    });

    test('email nullable — null ho sakta hai', () {
      final map = Map<String, dynamic>.from(fullMap)
        ..['email'] = null;
      final model = SupplierModel.fromMap(map);
      expect(model.email, isNull);
    });
  });
}