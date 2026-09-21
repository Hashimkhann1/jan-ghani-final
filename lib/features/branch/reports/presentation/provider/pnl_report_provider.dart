import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../accountant/branch_reports/accountant_profit_loss_report/presentation/provider/accountant_profit_loss_provider.dart';
import '../../data/datasource/pnl_report_datasource.dart';

/// Same notifier/state as the accountant P&L report — only the data source
/// differs (local branch Postgres instead of Supabase). Keyed by store id.
final branchPnlReportProvider =
    StateNotifierProvider.family<PnlReportNotifier, PnlReportState, String>(
  (ref, storeId) => PnlReportNotifier(storeId, source: BranchPnlDatasource()),
);
