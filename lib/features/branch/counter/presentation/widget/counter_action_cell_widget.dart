import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../../../warehouse/warehouse_user/presentation/widget/customer_action_button_widget.dart';

class CounterActionCellWidget extends StatelessWidget {
  const CounterActionCellWidget({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomerActionButton(
          icon:    Icons.edit_outlined,
          color:   AppColor.primary,
          tooltip: 'Edit',
          onTap:   onEdit,
        ),
        const SizedBox(width: 6),
        CustomerActionButton(
          icon:    Icons.delete_outline_rounded,
          color:   AppColor.error,
          tooltip: 'Delete',
          onTap:   onDelete,
        ),
      ],
    );
  }
}