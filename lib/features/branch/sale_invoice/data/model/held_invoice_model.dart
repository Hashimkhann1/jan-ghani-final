import 'package:jan_ghani_final/features/branch/customer/data/model/customer_model.dart';
import 'sale_invoice_model.dart';

/// ── HeldInvoice ───────────────────────────────────────────────
class HeldInvoice {
  final String         id;         // DB pk OR local uuid
  final String         invoiceNo;
  final String?        holdLabel;
  final CustomerModel? customer;
  final List<CartItem> cartItems;
  final DateTime       heldAt;
  final double         grandTotal;

  const HeldInvoice({
    required this.id,
    required this.invoiceNo,
    this.holdLabel,
    this.customer,
    required this.cartItems,
    required this.heldAt,
    required this.grandTotal,
  });

  /// UI display name for the held invoice chip
  String get displayLabel {
    if (holdLabel != null && holdLabel!.isNotEmpty) return holdLabel!;
    final name = customer?.name ?? 'Walk In';
    return '\$name — \$invoiceNo';
  }

  String get shortLabel {
    if (holdLabel != null && holdLabel!.isNotEmpty) return holdLabel!;
    return customer?.name ?? 'Walk In';
  }
}