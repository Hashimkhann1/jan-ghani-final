import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/core/widget/textfield/app_text_field.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customers"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              hint: "Search",
            ),
            16.hBox,
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: FigureCardWidget(
                    title: "Total Customer",
                    value: "200",
                    icon: Icons.add,
                  ),
                ),
                Expanded(
                  child: FigureCardWidget(
                    title: "Total Amount",
                    value: "200000",
                    icon: Icons.add,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
