import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Core brand color tokens for the Pure Monochrome Minimalist design system.
const Color kMonochromeBlack = Color(0xFF000000); // True AMOLED Black Base
const Color kMonochromeWhite = Color(0xFFFFFFFF); // Pure Crisp White
const Color kMonochromeCrimson = Color(
  0xFFFF453A,
); // 18+ Warning / Error Accent

// Aliases kept for compatibility
const Color kBrandCyan = kMonochromeWhite;
const Color kBrandPurple = Color(0xFFA1A1AA);
const Color kBrandObsidian = kMonochromeBlack;
const Color kBrandNeonCrimson = kMonochromeCrimson;

/// Signature elegant monochrome gradient applied to subtle highlights and active indicators.
const LinearGradient animedivesCyberGradient = LinearGradient(
  colors: [Color(0xFFFFFFFF), Color(0xFFA1A1AA)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Adaptive subtle border gradient that transitions with theme mode, providing a
/// crisp flat outline in dark mode and clean slate in light mode (zero elevation).
LinearGradient animedivesBorderGradient(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return const LinearGradient(
      colors: [Color(0xFF333338), Color(0xFF1E1E22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  return const LinearGradient(
    colors: [Color(0xFFE4E4E7), Color(0xFFD4D4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Extra design tokens for the Pure Monochrome design system.
@immutable
class AnimedivesColors extends ThemeExtension<AnimedivesColors> {
  final Color mutedForeground;
  final Color border;
  final Color input;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color cyanAccent;
  final Color purpleAccent;
  final Color cardSurface;
  final Color cardBorder;

  const AnimedivesColors({
    required this.mutedForeground,
    required this.border,
    required this.input,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.cyanAccent,
    required this.purpleAccent,
    required this.cardSurface,
    required this.cardBorder,
  });

  @override
  AnimedivesColors copyWith({
    Color? mutedForeground,
    Color? border,
    Color? input,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? cyanAccent,
    Color? purpleAccent,
    Color? cardSurface,
    Color? cardBorder,
  }) => AnimedivesColors(
    mutedForeground: mutedForeground ?? this.mutedForeground,
    border: border ?? this.border,
    input: input ?? this.input,
    accent: accent ?? this.accent,
    accentForeground: accentForeground ?? this.accentForeground,
    destructive: destructive ?? this.destructive,
    destructiveForeground: destructiveForeground ?? this.destructiveForeground,
    cyanAccent: cyanAccent ?? this.cyanAccent,
    purpleAccent: purpleAccent ?? this.purpleAccent,
    cardSurface: cardSurface ?? this.cardSurface,
    cardBorder: cardBorder ?? this.cardBorder,
  );

  @override
  AnimedivesColors lerp(ThemeExtension<AnimedivesColors>? other, double t) {
    if (other is! AnimedivesColors) return this;
    return AnimedivesColors(
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(
        accentForeground,
        other.accentForeground,
        t,
      )!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground: Color.lerp(
        destructiveForeground,
        other.destructiveForeground,
        t,
      )!,
      cyanAccent: Color.lerp(cyanAccent, other.cyanAccent, t)!,
      purpleAccent: Color.lerp(purpleAccent, other.purpleAccent, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
    );
  }
}

const AnimedivesColors lightAnimedivesColors = AnimedivesColors(
  mutedForeground: Color(0xFF71717A),
  border: Color(0xFFE4E4E7),
  input: Color(0xFFF4F4F5),
  accent: Color(0xFF09090B),
  accentForeground: Color(0xFFFFFFFF),
  destructive: Color(0xFFDC2626),
  destructiveForeground: Color(0xFFFFFFFF),
  cyanAccent: Color(0xFF09090B),
  purpleAccent: Color(0xFF71717A),
  cardSurface: Color(0xFFFFFFFF),
  cardBorder: Color(0xFFE4E4E7),
);

const AnimedivesColors darkAnimedivesColors = AnimedivesColors(
  mutedForeground: Color(0xFF8E8E93),
  border: Color(0xFF242428),
  input: Color(0xFF141416),
  accent: Color(0xFFFFFFFF),
  accentForeground: Color(0xFF000000),
  destructive: Color(0xFFFF453A),
  destructiveForeground: Color(0xFFFFFFFF),
  cyanAccent: Color(0xFFFFFFFF),
  purpleAccent: Color(0xFFA1A1AA),
  cardSurface: Color(0xFF0E0E10),
  cardBorder: Color(0xFF26262B),
);

const AnimedivesColors _lightAnimedives = lightAnimedivesColors;
const AnimedivesColors _darkAnimedives = darkAnimedivesColors;

/// Applies Bricolage Grotesque typography with crisp modern metrics.
TextTheme _bricolage(TextTheme base) =>
    GoogleFonts.bricolageGrotesqueTextTheme(base);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF09090B),
    onPrimary: const Color(0xFFFFFFFF),
    secondary: const Color(0xFFF4F4F5),
    onSecondary: const Color(0xFF09090B),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF09090B),
    surfaceContainerHighest: const Color(0xFFF4F4F5),
    error: kMonochromeCrimson,
    onError: const Color(0xFFFFFFFF),
    outline: const Color(0xFFE4E4E7),
    outlineVariant: const Color(0xFFF4F4F5),
    inverseSurface: const Color(0xFF09090B),
    inversePrimary: const Color(0xFFFFFFFF),
  ),
  extensions: const <ThemeExtension<dynamic>>[_lightAnimedives],
  textTheme: _bricolage(Typography.material2021().black),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Color(0xFF09090B),
  ),
  cardTheme: const CardThemeData(elevation: 0, color: Color(0xFFFFFFFF)),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF09090B),
      foregroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: const Color(0xFFF4F4F5),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  // Deep AMOLED Pure Black base.
  scaffoldBackgroundColor: kMonochromeBlack,
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFFFFFFFF),
    onPrimary: const Color(0xFF000000),
    secondary: const Color(0xFF18181B),
    onSecondary: const Color(0xFFFFFFFF),
    surface: const Color(0xFF000000),
    onSurface: const Color(0xFFFFFFFF),
    surfaceContainerHighest: const Color(0xFF141416),
    error: kMonochromeCrimson,
    onError: const Color(0xFFFFFFFF),
    outline: const Color(0xFF27272A),
    outlineVariant: const Color(0xFF3F3F46),
    inverseSurface: const Color(0xFFFFFFFF),
    inversePrimary: const Color(0xFF000000),
  ),
  extensions: const <ThemeExtension<dynamic>>[_darkAnimedives],
  textTheme: _bricolage(Typography.material2021().white),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Color(0xFFFFFFFF),
  ),
  cardTheme: const CardThemeData(elevation: 0, color: Color(0xFF0E0E10)),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: const Color(0xFF141416),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  ),
);
