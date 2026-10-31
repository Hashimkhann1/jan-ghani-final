import 'dart:js_interop';

// web/push.js (window.janGhaniPush) ke functions.
@JS('janGhaniPush.supported')
external bool _supported();

@JS('janGhaniPush.permission')
external String _permission();

@JS('janGhaniPush.subscribe')
external JSPromise<JSString> _subscribe(String vapidKey);

@JS('janGhaniPush.current')
external JSPromise<JSString> _current();

@JS('janGhaniPush.unsubscribe')
external JSPromise<JSString> _unsubscribe();

/// web/push.js ka Dart wrapper.
class PushPlatform {
  static bool get supported {
    try {
      return _supported();
    } catch (_) {
      return false;
    }
  }

  static String get permission {
    try {
      return _permission();
    } catch (_) {
      return 'denied';
    }
  }

  /// Subscription JSON string; '' agar ijazat nahi mili.
  static Future<String> subscribe(String vapidKey) async =>
      (await _subscribe(vapidKey).toDart).toDart;

  static Future<String> current() async => (await _current().toDart).toDart;

  /// Endpoint wapas deta hai; '' agar subscription thi hi nahi.
  static Future<String> unsubscribe() async =>
      (await _unsubscribe().toDart).toDart;
}
