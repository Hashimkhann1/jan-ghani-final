// test/widget_test.dart — replace karo
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jan_ghani_final/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(   // ← yeh add karo
        child: MyApp(),
      ),
    );
    // Counter test remove karo — tumhara app counter app nahi hai
  });
}