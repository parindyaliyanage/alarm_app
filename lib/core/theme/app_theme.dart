import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The themes a user can pick on first launch.
enum AppThemeChoice {
  teal(
    label: 'Teal',
    description: 'Chill & cool',
    mascot: 'assets/logos/bedzilla-hoodie-teal.png',
    reaction: 'Ooh, teal spikes! Very chill. Very me.',
    palette: AppPalette.teal,
  ),
  dustyRose(
    label: 'Dusty Rose',
    description: 'Sweet & cozy',
    mascot: 'assets/logos/bedzilla-hoodie-dusty-pink.png',
    reaction: 'Pink spikes? I look adorable. Still not letting you snooze.',
    palette: AppPalette.dustyRose,
  );

  final String label;
  final String description;

  /// Bedzilla artwork for this theme.
  final String mascot;

  /// What Bedzilla says when this theme is picked.
  final String reaction;
  final AppPalette palette;

  const AppThemeChoice({
    required this.label,
    required this.description,
    required this.mascot,
    required this.reaction,
    required this.palette,
  });

  ThemeData get themeData => buildAppTheme(palette);
}

/// `context.palette` — the active theme's colors.
extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Builds a dark [ThemeData] from a palette. Standard Material widgets
/// (switches, dialogs, buttons, inputs, pickers...) pick these up
/// automatically, and custom widgets read [AppPalette] via `context.palette`.
ThemeData buildAppTheme(AppPalette p) {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.accentContainer,
    onPrimaryContainer: p.highlight,
    secondary: p.highlight,
    onSecondary: p.onPrimary,
    error: p.error,
    onError: p.background,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.textMuted,
    surfaceContainerHighest: p.surfaceRaised,
    outline: p.border,
    outlineVariant: p.border,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
  );

  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    dividerColor: p.border,
    extensions: [p],
    textTheme: base.textTheme.apply(
      bodyColor: p.text,
      displayColor: p.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.primary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.primary : p.surfaceRaised,
      ),
      trackOutlineColor: WidgetStatePropertyAll(p.border),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      titleTextStyle: TextStyle(
        color: p.text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: p.textMuted, fontSize: 15),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceRaised,
      hintStyle: TextStyle(color: p.textMuted.withValues(alpha: 0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.primary, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.primary,
      selectionColor: p.primary.withValues(alpha: 0.35),
      selectionHandleColor: p.primary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceRaised,
      contentTextStyle: TextStyle(color: p.text),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.surface,
      dialBackgroundColor: p.surfaceRaised,
      hourMinuteColor: p.surfaceRaised,
      dayPeriodColor: p.accentContainer,
      entryModeIconColor: p.textMuted,
    ),
  );
}
