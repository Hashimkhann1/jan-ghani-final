/// Non-web builds: push support nahi.
class PushPlatform {
  static bool get supported => false;
  static String get permission => 'denied';
  static Future<String> subscribe(String vapidKey) async => '';
  static Future<String> current() async => '';
  static Future<String> unsubscribe() async => '';
}
