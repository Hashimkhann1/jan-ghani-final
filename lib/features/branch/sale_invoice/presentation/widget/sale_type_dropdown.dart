import 'package:flutter/material.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';

class SaleTypeDropdown extends StatelessWidget {
  final SaleType value;
  final ValueChanged<SaleType?> onChanged;

  const SaleTypeDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isReturn = value == SaleType.saleReturn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColor.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<SaleType>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          style: TextStyle(
            fontSize: 12,
            color: isReturn ? AppColor.error : AppColor.success,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              isReturn ? Icons.assignment_return_outlined : Icons.point_of_sale_outlined,
              size: 16,
              color: isReturn ? AppColor.error : AppColor.success,
            ),
            filled: true,
            fillColor: isReturn ? AppColor.errorLight.withOpacity(0.2) : AppColor.success.withOpacity(0.08),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isReturn ? AppColor.error : AppColor.success,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isReturn ? AppColor.error : AppColor.success,
                width: 1.5,
              ),
            ),
          ),
          items: SaleType.values.map((type) => DropdownMenuItem<SaleType>(
            value: type,
            child: Text(
              type.label,
              style: TextStyle(
                fontSize: 12,
                color: type == SaleType.saleReturn ? AppColor.error : AppColor.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}
