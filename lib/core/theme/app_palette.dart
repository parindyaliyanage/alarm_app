import 'package:flutter/material.dart';

/// The app's custom colors, attached to [ThemeData] as a [ThemeExtension].
///
/// Read it in any widget with `context.palette` (see app_theme.dart).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface; // cards
  final Color surfaceRaised; // elevated cards, chips, inputs
  final Color border;
  final Color primary; // accent
  final Color accentContainer; // tinted background behind accent content
  final Color highlight; // lighter accent
  final Color text;
  final Color textMuted;
  final Color success;
  final Color error;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.primary,
    required this.accentContainer,
    required this.highlight,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.error,
  });

  /// Accent gradient: highlight → primary.
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, primary],
      );

  /// Text/icon color to use on top of [primary] or [gradient].
  Color get onPrimary => background;

  // ── Themes ──────────────────────────────────────────────────────

  static const teal = AppPalette(
    background: Color(0xFF17151D),
    surface: Color(0xFF211E29),
    surfaceRaised: Color(0xFF2C2835),
    border: Color(0xFF393442),
    primary: Color(0xFF87BDBC),
    accentContainer: Color(0xFF263B3C),
    highlight: Color(0xFFB0D5D3),
    text: Color(0xFFF8F2ED),
    textMuted: Color(0xFFAAA3B2),
    success: Color(0xFF9BD4A8),
    error: Color(0xFFE5838A),
  );

  static const dustyRose = AppPalette(
    background: Color(0xFF17151D),
    surface: Color(0xFF211E29),
    surfaceRaised: Color(0xFF2C2835),
    border: Color(0xFF393442),
    primary: Color(0xFFC98FA5),
    accentContainer: Color(0xFF402B37),
    highlight: Color(0xFFE1B6C5),
    text: Color(0xFFF8F2ED),
    textMuted: Color(0xFFAAA3B2),
    success: Color(0xFF9BD4A8),
    error: Color(0xFFE5838A),
  );

  // ── ThemeExtension plumbing ─────────────────────────────────────

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? primary,
    Color? accentContainer,
    Color? highlight,
    Color? text,
    Color? textMuted,
    Color? success,
    Color? error,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      accentContainer: accentContainer ?? this.accentContainer,
      highlight: highlight ?? this.highlight,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }

  /// Lets the app animate smoothly when the theme changes.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      border: l(border, other.border),
      primary: l(primary, other.primary),
      accentContainer: l(accentContainer, other.accentContainer),
      highlight: l(highlight, other.highlight),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      success: l(success, other.success),
      error: l(error, other.error),
    );
  }
}
