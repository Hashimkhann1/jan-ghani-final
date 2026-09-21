import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../accountant/branch_reports/product_profit_loss_report/presentation/screen/product_profit_loss_report_screen.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../provider/product_profit_loss_provider.dart';

/// Branch sidebar entry for the product profit/loss report. Reuses the
/// accountant screen, pointed at this branch's local database.
class BranchProductProfitLossScreen extends ConsumerWidget {
  const BranchProductProfitLossScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeId = ref.watch(authProvider).storeId;
    return ProductProfitLossReportScreen(
      branchId: storeId,
      provider: branchProductProfitLossProvider,
      showBack: false,
    );
  }
}
