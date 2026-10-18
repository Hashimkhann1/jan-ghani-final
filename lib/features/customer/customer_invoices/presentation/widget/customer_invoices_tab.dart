import 'package:flutter/material.dart';
import '../../data/datasource/customer_report_datasource.dart';
import '../screen/customer_report_screen.dart';

/// Customer ki invoice history (invoices, returns, ledger, search, date filter).
/// Naam aur balance customer table se tab khulte hi aate hain.
class CustomerInvoicesTab extends StatefulWidget {
  final String customerId;
  const CustomerInvoicesTab({super.key, required this.customerId});

  @override
  State<CustomerInvoicesTab> createState() => _CustomerInvoicesTabState();
}

class _CustomerInvoicesTabState extends State<CustomerInvoicesTab> {
  late final Future<Map<String, dynamic>?> _info =
      CustomerReportDatasource().getCustomerInfo(widget.customerId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _info,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final row = snap.data;
        return CustomerReportScreen(
          customerId: widget.customerId,
          customerName: row?['name'] as String? ?? 'Customer',
          customerBalance: row?['balance'] as double? ?? 0.0,
          hideAppBarBack: true,
        );
      },
    );
  }
}
