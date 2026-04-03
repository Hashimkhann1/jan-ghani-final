import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Jan Ghani',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FigureCardWidget(
                  title: "Total Sale Balance",
                  value: "1200",
                  icon: Icons.do_not_disturb_on_total_silence,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
