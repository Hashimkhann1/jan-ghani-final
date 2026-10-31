import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_platform.dart';

/// Customer ki PWA mein sale notification on/off.
///
/// VAPID **public** key yahan daalni hai (`npx web-push generate-vapid-keys`).
/// Private key sirf Supabase Edge Function ke secrets mein jati hai.
const String kVapidPublicKey =
    'BNyNaa-tfpsnKO5SO1YWZnLPt74f0tFiFpHhEua7woz4T_FWH8bhjIgis4YaBxRlTw8DXIlNJGNPjH48jPX1ynU';

class CustomerPushService {
  static SupabaseClient get _sb => Supabase.instance.client;

  /// Browser/device par push chal sakta hai aur key set hai?
  static bool get available => kVapidPublicKey.isNotEmpty && PushPlatform.supported;

  /// Is device par notification pehle se on hai?
  static Future<bool> isEnabled() async {
    if (!available) return false;
    final json = await PushPlatform.current();
    if (json.isEmpty) return false;
    final ep = (jsonDecode(json) as Map)['endpoint'] as String?;
    final uid = _sb.auth.currentUser?.id;
    if (ep == null || uid == null) return false;
    final row = await _sb
        .from('customer_push_subscriptions')
        .select('id')
        .eq('endpoint', ep)
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  /// Ijazat maange, subscribe kare, DB mein save kare. false = ijazat nahi mili.
  static Future<bool> enable() async {
    final uid = _sb.auth.currentUser?.id;
    if (!available || uid == null) return false;
    final json = await PushPlatform.subscribe(kVapidPublicKey);
    if (json.isEmpty) return false;
    final sub  = jsonDecode(json) as Map<String, dynamic>;
    final keys = sub['keys'] as Map<String, dynamic>;
    await _sb.from('customer_push_subscriptions').upsert({
      'user_id':  uid,
      'endpoint': sub['endpoint'],
      'p256dh':   keys['p256dh'],
      'auth':     keys['auth'],
    }, onConflict: 'endpoint');
    return true;
  }

  static Future<void> disable() async {
    final ep = await PushPlatform.unsubscribe();
    if (ep.isNotEmpty) {
      await _sb.from('customer_push_subscriptions').delete().eq('endpoint', ep);
    }
  }
}
