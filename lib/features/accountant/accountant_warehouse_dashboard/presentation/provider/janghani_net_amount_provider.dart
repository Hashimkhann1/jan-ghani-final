import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================
// janghani_net_amount — accountant department ka live cash balance
// (single row). Read-only fetch for Send Cash dialog.
// =============================================================
final janghaniCashInHandProvider = FutureProvider<double>((ref) async {
  final res = await Supabase.instance.client
      .from('janghani_net_amount')
      .select('cash_in_hand')
      .limit(1)
      .maybeSingle();

  final v = res?['cash_in_hand'];
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
});
