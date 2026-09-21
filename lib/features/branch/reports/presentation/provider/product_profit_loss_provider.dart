import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../accountant/branch_reports/product_profit_loss_report/presentation/provider/product_profit_loss_provider.dart';
import '../../data/datasource/product_profit_loss_datasource.dart';

/// Same notifier/state as the accountant report — only the data source
/// differs (local branch Postgres instead of Supabase). Keyed by store id.
final branchProductProfitLossProvider = StateNotifierProvider.autoDispose
    .family<ProductProfitLossNotifier, ProductProfitLossState, String>(
  (ref, storeId) => ProductProfitLossNotifier(
    source: BranchProductProfitLossDatasource(storeId: storeId),
  ),
);
