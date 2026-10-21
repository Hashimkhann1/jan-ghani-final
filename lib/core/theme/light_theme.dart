import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LightTheme {
  LightTheme._();

  // ─────────────────────────────────────────
  // COLORS
  // ─────────────────────────────────────────
  static const Color _primary       = Color(0xFF6C63FF);
  static const Color _primaryLight  = Color(0xFF9D97FF);
  static const Color _primaryDark   = Color(0xFF3D35CC);
  static const Color _secondary     = Color(0xFF03DAC6);
  static const Color _background    = Color(0xFFF5F5F5);
  static const Color _surface       = Color(0xFFFFFFFF);
  static const Color _error         = Color(0xFFE53935);
  static const Color _textPrimary   = Color(0xFF212121);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _textHint      = Color(0xFFBDBDBD);
  static const Color _divider       = Color(0xFFE0E0E0);
  static const Color _border        = Color(0xFFBDBDBD);
  static const Color _shadow        = Color(0x1A000000);

  // ─────────────────────────────────────────
  // MAIN THEME
  // ─────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: _background,
    splashColor: _primary.withValues(alpha: 0.08),
    highlightColor: _primary.withValues(alpha: 0.04),
    dividerColor: _divider,
    disabledColor: _textHint,

    // ── Color Scheme ──
    colorScheme: const ColorScheme.light(
      primary: _primary,
      primaryContainer: _primaryLight,
      onPrimary: Colors.white,
      onPrimaryContainer: _primaryDark,
      secondary: _secondary,
      onSecondary: Colors.white,
      surface: _surface,
      onSurface: _textPrimary,
      error: _error,
      onError: Colors.white,
      outline: _border,
      shadow: _shadow,
    ),

    // ── AppBar ──
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _surface,
      foregroundColor: _textPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: _textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      iconTheme: IconThemeData(color: _textPrimary, size: 24),
      actionsIconTheme: IconThemeData(color: _textPrimary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),

    // ── Text ──
    textTheme: const TextTheme(
      displayLarge:   TextStyle(fontSize: 57, fontWeight: FontWeight.w700, color: _textPrimary, height: 1.2),
      displayMedium:  TextStyle(fontSize: 45, fontWeight: FontWeight.w600, color: _textPrimary, height: 1.2),
      displaySmall:   TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: _textPrimary, height: 1.2),
      headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _textPrimary, height: 1.3),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: _textPrimary, height: 1.3),
      headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _textPrimary, height: 1.3),
      titleLarge:     TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary),
      titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _textPrimary),
      titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary),
      bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: _textPrimary, height: 1.5),
      bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _textPrimary, height: 1.5),
      bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _textSecondary, height: 1.5),
      labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
      labelMedium:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary),
      labelSmall:     TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _textHint, letterSpacing: 0.5),
    ),

    // ── ElevatedButton ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _textHint,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    // ── OutlinedButton ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: _primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    // ── TextButton ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    // ── InputDecoration (TextField) ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: _textHint, fontSize: 14),
      labelStyle: const TextStyle(color: _textSecondary, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: _primary, fontSize: 13),
      prefixIconColor: _textSecondary,
      suffixIconColor: _textSecondary,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _error, width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _border.withValues(alpha: 0.5), width: 1),
      ),
      errorStyle: const TextStyle(color: _error, fontSize: 12),
    ),

    // ── Card ──
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 2,
      shadowColor: _shadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
    ),

    // ── BottomNavigationBar ──
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surface,
      selectedItemColor: _primary,
      unselectedItemColor: _textHint,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),

    // ── NavigationBar (Material 3) ──
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _surface,
      indicatorColor: _primary.withValues(alpha: 0.15),
      // ✅ WidgetStateProperty instead of MaterialStateProperty
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _primary, size: 24);
        }
        return const IconThemeData(color: _textHint, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: _textHint, fontSize: 11);
      }),
      elevation: 8,
    ),

    // ── Floating Action Button ──
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // ── Chip ──
    chipTheme: ChipThemeData(
      backgroundColor: _background,
      selectedColor: _primary.withValues(alpha: 0.15),
      labelStyle: const TextStyle(fontSize: 13, color: _textPrimary),
      side: const BorderSide(color: _border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: _surface,
      elevation: 8,
      shadowColor: _shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        fontFamily: 'Poppins',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: _textSecondary,
        fontFamily: 'Poppins',
      ),
    ),

    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      actionTextColor: _primaryLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),

    // ── Checkbox ──
    checkboxTheme: CheckboxThemeData(
      // ✅ WidgetStateProperty instead of MaterialStateProperty
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: _border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // ── Radio ──
    radioTheme: RadioThemeData(
      // ✅ WidgetStateProperty instead of MaterialStateProperty
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primary;
        return _border;
      }),
    ),

    // ── Switch ──
    switchTheme: SwitchThemeData(
      // ✅ WidgetStateProperty instead of MaterialStateProperty
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return _textHint;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primary;
        return _border;
      }),
    ),

    // ── Slider ──
    sliderTheme: SliderThemeData(
      activeTrackColor: _primary,
      inactiveTrackColor: _primary.withValues(alpha: 0.2),
      thumbColor: _primary,
      overlayColor: _primary.withValues(alpha: 0.12),
      valueIndicatorColor: _primary,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),

    // ── TabBar ──
    tabBarTheme: const TabBarThemeData(
      labelColor: _primary,
      unselectedLabelColor: _textSecondary,
      indicatorColor: _primary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    ),

    // ── Divider ──
    dividerTheme: const DividerThemeData(
      color: _divider,
      thickness: 1,
      space: 1,
    ),

    // ── ListTile ──
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: _textSecondary,
      textColor: _textPrimary,
      titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textPrimary),
      subtitleTextStyle: TextStyle(fontSize: 13, color: _textSecondary),
    ),

    // ── BottomSheet ──
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // ── Progress Indicator ──
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primary,
      linearTrackColor: _divider,
      circularTrackColor: _divider,
    ),

    // ── Icon ──
    iconTheme: const IconThemeData(color: _textPrimary, size: 24),
    primaryIconTheme: const IconThemeData(color: Colors.white, size: 24),
  );
}