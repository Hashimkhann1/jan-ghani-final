import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasource/branch_datasource.dart';
import '../../data/model/branch_model.dart';

final branchDatasourceProvider = Provider<BranchDatasource>((ref) {
  return BranchDatasource(Supabase.instance.client);
});

final branchProvider =
FutureProvider.autoDispose.family<BranchModel?, String>((ref, branchId) {
  final datasource = ref.watch(branchDatasourceProvider);
  return datasource.getBranchById(branchId);
});