import 'package:flutter/material.dart';

class FormRow extends StatelessWidget {
  final List<Widget> children;
  const FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 14)])
          .toList()
        ..removeLast(),
    );
  }
}
