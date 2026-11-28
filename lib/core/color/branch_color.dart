import 'package:flutter/material.dart';

/// Branch app ke navy + sunehri colors — sidebar aur saari Branch
/// screens yahi se lete hain. (`AppColor` poori app mein use hota hai, is liye
/// usay nahi chhera.)
class BranchColor {
  BranchColor._();

  static const navy   = Color(0xFF0B1B3A); // main / primary
  static const slate  = Color(0xFF303E5A); // selected
  static const accent = Color(0xFFD6A650); // sunehri

  // ── Table header: sidebar jaisa ──
  static const header   = navy;
  static const onHeader = Colors.white;

  // ── Form / button style ──
  static const line      = Color(0xFFD5DAE4); // field aur button ka border
  static const lineSoft  = Color(0xFFE6E9F0); // disabled
  static const hint      = Color(0xFF98A1B3);
  static const radius    = 10.0;

  static OutlineInputBorder _field(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide:   BorderSide(color: color, width: width),
      );

  static final _shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius));

  static const gradient = LinearGradient(
    colors: [slate, navy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// App theme ka woh hissa jo jamni (purple) hai — text field focus,
  /// buttons, loader waghera — usay navy kar deta hai.
  static ThemeData theme(ThemeData base) {
    final input = base.inputDecorationTheme;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary:            navy,
        primaryContainer:   slate,
        onPrimaryContainer: Colors.white,
        secondary:          accent,
        secondaryContainer:   const Color(0xFFE8EAF0),
        onSecondaryContainer: navy,
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor:     navy,
        indicatorColor: navy,
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: navy.withValues(alpha: 0.15),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor:   navy,
        inactiveTrackColor: navy.withValues(alpha: 0.2),
        thumbColor:         navy,
      ),
      splashColor:    navy.withValues(alpha: 0.08),
      highlightColor: navy.withValues(alpha: 0.04),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor:          navy,
        selectionColor:       navy.withValues(alpha: 0.18),
        selectionHandleColor: navy,
      ),
      inputDecorationTheme: input.copyWith(
        filled:     true,
        fillColor:  Colors.white,
        hintStyle:  const TextStyle(color: hint, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: navy, fontSize: 13),
        prefixIconColor:    hint,
        suffixIconColor:    hint,
        border:             _field(line),
        enabledBorder:      _field(line),
        focusedBorder:      _field(navy, 1.5),
        disabledBorder:     _field(lineSoft),
        errorBorder:        _field(const Color(0xFFE53935)),
        focusedErrorBorder: _field(const Color(0xFFE53935), 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          shape: _shape,
        ).merge(base.elevatedButtonTheme.style),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          shape: _shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: line, width: 1.2),
          shape: _shape,
        ).merge(base.outlinedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: navy, shape: _shape)
            .merge(base.textButtonTheme.style),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? navy : null),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? Colors.white : null),
        ),
      ),
      dataTableTheme: base.dataTableTheme.copyWith(
        headingRowColor: const WidgetStatePropertyAll(header),
        headingTextStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: onHeader),
      ),
      progressIndicatorTheme:
          base.progressIndicatorTheme.copyWith(color: navy),
      checkboxTheme: base.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? navy : Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? navy : const Color(0xFFBDBDBD)),
      ),
      switchTheme: base.switchTheme.copyWith(
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? navy : const Color(0xFFBDBDBD)),
      ),
    );
  }
}
