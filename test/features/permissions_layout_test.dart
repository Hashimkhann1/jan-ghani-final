import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/features/branch/permissions/presentation/screen/permissions_screen.dart';
import 'package:jan_ghani_final/features/branch/store_user/data/model/user_model.dart';

UserModel _user(String role) => UserModel(
      id: 'u1',
      storeId: 's1',
      username: 'ahmad_khan_with_a_really_long_username_here',
      passwordHash: '',
      fullName: 'Ahmad Khan With A Very Long Full Name Indeed',
      role: role,
      isActive: true,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(1440, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Permissions'), toolbarHeight: 60),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.blue.shade50,
                  child: const Text('info banner'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(width: 280),
                      const SizedBox(width: 16),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final role in ['cashier', 'store_manager', 'stock_officer']) {
    testWidgets('PermissionEditor lays out for $role', (tester) async {
      await _pump(tester, PermissionEditor(user: _user(role)));
      expect(tester.takeException(), isNull);
      expect(find.text('Save'), findsOneWidget);
    });
  }

  testWidgets('PermissionEditor lays out for owner (locked)', (tester) async {
    await _pump(tester, PermissionEditor(user: _user('store_owner')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PermissionEditor lays out on a narrow window', (tester) async {
    await _pump(tester, PermissionEditor(user: _user('cashier')),
        size: const Size(1000, 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggling a module action does not throw', (tester) async {
    await _pump(tester, PermissionEditor(user: _user('cashier')));
    await tester.tap(find.text('Grant all'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Revoke all'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
