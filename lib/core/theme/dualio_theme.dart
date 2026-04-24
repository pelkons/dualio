import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class DualioColors {
  static const surface = Color(0xFFFDF8F8);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF7F3F2);
  static const surfaceContainer = Color(0xFFF1EDEC);
  static const surfaceContainerHigh = Color(0xFFEBE7E6);
  static const surfaceContainerHighest = Color(0xFFE5E2E1);
  static const onSurface = Color(0xFF1C1B1B);
  static const onSurfaceVariant = Color(0xFF444748);
  static const outline = Color(0xFF747878);
  static const outlineVariant = Color(0xFFC4C7C7);

  static const darkSurface = Color(0xFF121212);
  static const darkSurfaceContainerLowest = Color(0xFF1A1A1A);
  static const darkSurfaceContainerLow = Color(0xFF202020);
  static const darkSurfaceContainer = Color(0xFF262626);
  static const darkSurfaceContainerHighest = Color(0xFF333333);
  static const darkOnSurface = Color(0xFFF4F0EF);
  static const darkOnSurfaceVariant = Color(0xFFC8C6C5);
}

abstract final class DualioTheme {
  static const double cardRadius = 14;
  static const double innerRadius = 8;
  static const double mobileMargin = 24;

  static ThemeData light() {
    return _theme(
      brightness: Brightness.light,
      surface: DualioColors.surface,
      card: DualioColors.surfaceContainerLowest,
      subtle: DualioColors.surfaceContainerLow,
      pill: DualioColors.surfaceContainerHighest,
      text: DualioColors.onSurface,
      muted: DualioColors.onSurfaceVariant,
      outline: DualioColors.outlineVariant,
    );
  }

  static ThemeData dark() {
    return _theme(
      brightness: Brightness.dark,
      surface: DualioColors.darkSurface,
      card: DualioColors.darkSurfaceContainerLowest,
      subtle: DualioColors.darkSurfaceContainerLow,
      pill: DualioColors.darkSurfaceContainerHighest,
      text: DualioColors.darkOnSurface,
      muted: DualioColors.darkOnSurfaceVariant,
      outline: const Color(0xFF3C3C3C),
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color surface,
    required Color card,
    required Color subtle,
    required Color pill,
    required Color text,
    required Color muted,
    required Color outline,
  }) {
    final serif = GoogleFonts.notoSerifTextTheme();
    final sans = GoogleFonts.manropeTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: brightness,
        surface: surface,
        primary: brightness == Brightness.light ? Colors.black : Colors.white,
      ),
      extensions: <ThemeExtension<dynamic>>[
        DualioPalette(card: card, subtle: subtle, pill: pill, muted: muted, outline: outline),
      ],
      textTheme: sans.copyWith(
        displayLarge: serif.displayLarge?.copyWith(fontSize: 36, fontWeight: FontWeight.w600, height: 1.2, color: text),
        headlineMedium: serif.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w500, height: 1.3, color: text),
        titleLarge: serif.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.25, color: text),
        bodyMedium: sans.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: text),
        labelSmall: sans.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2, color: muted),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: card,
        foregroundColor: text,
        titleTextStyle: serif.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}

class DualioPalette extends ThemeExtension<DualioPalette> {
  const DualioPalette({
    required this.card,
    required this.subtle,
    required this.pill,
    required this.muted,
    required this.outline,
  });

  final Color card;
  final Color subtle;
  final Color pill;
  final Color muted;
  final Color outline;

  @override
  DualioPalette copyWith({Color? card, Color? subtle, Color? pill, Color? muted, Color? outline}) {
    return DualioPalette(
      card: card ?? this.card,
      subtle: subtle ?? this.subtle,
      pill: pill ?? this.pill,
      muted: muted ?? this.muted,
      outline: outline ?? this.outline,
    );
  }

  @override
  DualioPalette lerp(ThemeExtension<DualioPalette>? other, double t) {
    if (other is! DualioPalette) {
      return this;
    }
    return DualioPalette(
      card: Color.lerp(card, other.card, t) ?? card,
      subtle: Color.lerp(subtle, other.subtle, t) ?? subtle,
      pill: Color.lerp(pill, other.pill, t) ?? pill,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
    );
  }
}
