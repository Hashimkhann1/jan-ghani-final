import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../accountant/branch_reports/accountant_profit_loss_report/presentation/screen/accountant_profit_loss_report_screen.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../provider/pnl_report_provider.dart';

/// Branch sidebar entry for the Sale Summary Profit & Loss report. Reuses
/// the accountant screen, pointed at this branch's local database.
class BranchPnlReportScreen extends ConsumerWidget {
  const BranchPnlReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeId = ref.watch(authProvider).storeId;
    return PnlReportScreen(
      branchId: storeId,
      provider: branchPnlReportProvider,
    );
  }
}
