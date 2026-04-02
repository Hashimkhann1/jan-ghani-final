
import 'package:flutter/material.dart';

extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  /// Capitalize each word
  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  /// Check if valid email
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// Check if valid phone (10-13 digits)
  bool get isValidPhone => RegExp(r'^\+?[0-9]{10,13}$').hasMatch(this);

  /// Check if valid URL
  bool get isValidUrl => RegExp(r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}').hasMatch(this);

  /// Remove extra spaces
  String get clean => trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Check if null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Convert to int safely
  int get toInt => int.tryParse(this) ?? 0;

  /// Convert to double safely
  double get toDouble => double.tryParse(this) ?? 0.0;

  /// Mask phone number → 03**-*****89
  String get maskPhone => length < 4 ? this : '${substring(0, 2)}****${substring(length - 2)}';

  /// Truncate with ellipsis
  String truncate(int maxLength) => length <= maxLength ? this : '${substring(0, maxLength)}...';
}

/// STRING? (NULLABLE) EXTENSIONS
extension NullableStringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String get orEmpty => this ?? '';
}

/// CONTEXT EXTENSIONS
extension ContextExtension on BuildContext {
  /// Screen size
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Keyboard
  bool get isKeyboardOpen => MediaQuery.of(this).viewInsets.bottom > 0;
  void hideKeyboard() => FocusScope.of(this).unfocus();

  /// Theme
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Navigation
  void pop([dynamic result]) => Navigator.of(this).pop(result);
  Future push(Widget page) => Navigator.of(this).push(MaterialPageRoute(builder: (_) => page));
  Future pushReplacement(Widget page) => Navigator.of(this).pushReplacement(MaterialPageRoute(builder: (_) => page));
  Future pushAndClearAll(Widget page) => Navigator.of(this).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => page), (route) => false);

  /// SnackBar
  void showSnackBar(String message, {Color? backgroundColor, Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  /// Screen type
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;
}

/// INT EXTENSIONS
extension IntExtension on int {
  /// SizedBox helpers
  SizedBox get hBox => SizedBox(height: toDouble());
  SizedBox get wBox => SizedBox(width: toDouble());

  /// Padding helpers
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());
  EdgeInsets get hPadding => EdgeInsets.symmetric(horizontal: toDouble());
  EdgeInsets get vPadding => EdgeInsets.symmetric(vertical: toDouble());

  /// Duration
  Duration get seconds => Duration(seconds: this);
  Duration get milliseconds => Duration(milliseconds: this);
  Duration get minutes => Duration(minutes: this);

  /// Readable number  1000 → "1K"
  String get compact {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K';
    return toString();
  }
}

/// DOUBLE EXTENSIONS
extension DoubleExtension on double {
  SizedBox get hBox => SizedBox(height: this);
  SizedBox get wBox => SizedBox(width: this);
  EdgeInsets get allPadding => EdgeInsets.all(this);
  EdgeInsets get hPadding => EdgeInsets.symmetric(horizontal: this);
  EdgeInsets get vPadding => EdgeInsets.symmetric(vertical: this);
  BorderRadius get roundedAll => BorderRadius.circular(this);
}

/// WIDGET EXTENSIONS

extension WidgetExtension on Widget {
  /// Padding
  Widget padAll(double value) => Padding(padding: EdgeInsets.all(value), child: this);
  Widget padHorizontal(double value) => Padding(padding: EdgeInsets.symmetric(horizontal: value), child: this);
  Widget padVertical(double value) => Padding(padding: EdgeInsets.symmetric(vertical: value), child: this);
  Widget padOnly({double left = 0, double right = 0, double top = 0, double bottom = 0}) => Padding(padding: EdgeInsets.only(left: left, right: right, top: top, bottom: bottom), child: this);

  /// Alignment
  Widget get center => Center(child: this);
  Widget get alignLeft => Align(alignment: Alignment.centerLeft, child: this);
  Widget get alignRight => Align(alignment: Alignment.centerRight, child: this);

  /// Expanded / Flexible
  Widget get expanded => Expanded(child: this);
  Widget flexible({int flex = 1}) => Flexible(flex: flex, child: this);

  /// Visibility
  Widget visible(bool isVisible) => Visibility(visible: isVisible, child: this);

  /// Gesture
  Widget onTap(VoidCallback onTap) => GestureDetector(onTap: onTap, child: this);

  /// Opacity
  Widget withOpacity(double opacity) => Opacity(opacity: opacity, child: this);

  /// ClipRRect
  Widget rounded(double radius) => ClipRRect(borderRadius: BorderRadius.circular(radius), child: this);

  /// Card Wrap
  Widget get asCard => Card(child: this);

  /// SafeArea
  Widget get safeArea => SafeArea(child: this);

  /// SliverToBoxAdapter
  Widget get asSliver => SliverToBoxAdapter(child: this);
}

/// DATETIME EXTENSIONS
extension DateTimeExtension on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return day == now.day && month == now.month && year == now.year;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return day == yesterday.day && month == yesterday.month && year == yesterday.year;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return day == tomorrow.day && month == tomorrow.month && year == tomorrow.year;
  }

  /// Time ago
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Format
  String get ddMMYYYY => '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';
  String get hhMM {
    final h = hour > 12 ? hour - 12 : hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

/// LIST EXTENSIONS
extension ListExtension<T> on List<T> {
  /// Safe get
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
  T? elementAtOrNull(int index) => (index >= 0 && index < length) ? this[index] : null;

  /// Chunk list  [1,2,3,4,5].chunk(2) → [[1,2],[3,4],[5]]
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  /// Remove duplicates
  List<T> get unique => toSet().toList();
}

/// COLOR EXTENSIONS
extension ColorExtension on Color {
  /// Darken color
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Lighten color
  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Convert to hex string
  String get toHex => '#${value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// With custom opacity
  Color withAlphaValue(int alpha) => withAlpha(alpha);
}

/// NUM EXTENSIONS

extension NumExtension on num {
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
  bool get isZero => this == 0;

  /// Clamp between min and max
  num clampTo(num min, num max) => clamp(min, max);

  /// Percentage  50.percentOf(200) → 100
  double percentOf(double total) => total * this / 100;
}


/*
// String
'hello world'.titleCase       // → "Hello World"
'test@gmail.com'.isValidEmail // → true
'03001234567'.maskPhone       // → "03****67"
'Long text...'.truncate(10)   // → "Long text..."

// Context
context.screenWidth
context.isDarkMode
context.push(HomePage())
context.showSnackBar('Saved!')

// Widget
Text('Hi').padAll(16).center.onTap(() => print('tapped'))

// Int
16.hBox    // SizedBox(height: 16)
2.seconds  // Duration(seconds: 2)
1500.compact // → "1.5K"

// DateTime
DateTime.now().timeAgo   // → "Just now"
DateTime.now().ddMMYYYY  // → "02-04-2026"

// List
[1, 2, 2, 3].unique      // → [1, 2, 3]
[1,2,3,4,5].chunk(2)     // → [[1,2],[3,4],[5]]

 */