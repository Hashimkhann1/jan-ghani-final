import 'package:flutter/material.dart';

class ExpiryField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const ExpiryField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = date != null
        ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
        : 'Select expiry date (optional)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Expiry Date",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: date != null
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null
                          ? const Color(0xFF1A1D23)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                ),
                if (date != null)
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
