// =============================================================
// po_type_dropdown.dart
// Sale Invoice SaleTypeDropdown ki tarah
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/purchase_invoice/data/purchase_invoice_model.dart';


class PoTypeDropdown extends StatelessWidget {
  final PoType                value;
  final ValueChanged<PoType?> onChanged;

  const PoTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isReturn = value == PoType.purchaseReturn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type',
            style: TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<PoType>(
          value:      value,
          onChanged:  onChanged,
          isExpanded: true,
          style: TextStyle(
              fontSize:   12,
              color: isReturn ? AppColor.error : AppColor.primary,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(
              isReturn
                  ? Icons.assignment_return_outlined
                  : Icons.shopping_bag_outlined,
              size:  16,
              color: isReturn ? AppColor.error : AppColor.primary,
            ),
            filled:    true,
            fillColor: isReturn
                ? AppColor.errorLight.withOpacity(0.2)
                : AppColor.primary.withOpacity(0.08),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:   BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: isReturn
                      ? AppColor.error : AppColor.primary,
                  width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: isReturn
                      ? AppColor.error : AppColor.primary,
                  width: 1.5),
            ),
          ),
          items: PoType.values
              .map((type) => DropdownMenuItem<PoType>(
                    value: type,
                    child: Text(type.label,
                        style: TextStyle(
                            fontSize:   12,
                            color: type == PoType.purchaseReturn
                                ? AppColor.error
                                : AppColor.primary,
                            fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
