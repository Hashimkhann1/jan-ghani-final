import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/branch_datasource.dart';
import '../../data/model/branch_model.dart';

final branchDatasourceProvider = Provider<BranchDatasource>((ref) {
  return BranchDatasource();
});

final branchProvider =
FutureProvider.autoDispose.family<BranchModel?, String>((ref, branchId) {
  final datasource = ref.watch(branchDatasourceProvider);
  return datasource.getBranchById(branchId);
});