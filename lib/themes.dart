import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Core brand color tokens for the Electric Cyber Glassmorphism design system.
const Color kBrandCyan = Color(0xFF00E5FF); // Electric Cyan
const Color kBrandPurple = Color(0xFFB388FF); // Cyber Violet
const Color kBrandObsidian = Color(0xFF08080A); // AMOLED True Black Base
const Color kBrandNeonCrimson = Color(0xFFFF3366); // 18+ Warning / Error Accent

/// Signature vibrant linear gradient applied to glowing cards, borders,
/// hero buttons, and active indicators.
const LinearGradient animedivesCyberGradient = LinearGradient(
  colors: [kBrandCyan, kBrandPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Adaptive border gradient that transitions with theme mode, providing a
/// crisp luminous outline in dark mode and clean cyber slate in light mode.
LinearGradient animedivesBorderGradient(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return const LinearGradient(
      colors: [Color(0x9900E5FF), Color(0x33B388FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  return const LinearGradient(
    colors: [Color(0x6600E5FF), Color(0x22B388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Extra design tokens for the Electric Cyber Glassmorphism system.
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
  }) =>
      AnimedivesColors(
        mutedForeground: mutedForeground ?? this.mutedForeground,
        border: border ?? this.border,
        input: input ?? this.input,
        accent: accent ?? this.accent,
        accentForeground: accentForeground ?? this.accentForeground,
        destructive: destructive ?? this.destructive,
        destructiveForeground:
            destructiveForeground ?? this.destructiveForeground,
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
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground:
          Color.lerp(destructiveForeground, other.destructiveForeground, t)!,
      cyanAccent: Color.lerp(cyanAccent, other.cyanAccent, t)!,
      purpleAccent: Color.lerp(purpleAccent, other.purpleAccent, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
    );
  }
}

const AnimedivesColors lightAnimedivesColors = AnimedivesColors(
  mutedForeground: Color(0xFF6B7280),
  border: Color(0xFFE5E7EB),
  input: Color(0xFFF3F4F6),
  accent: Color(0xFF00E5FF),
  accentForeground: Color(0xFF000000),
  destructive: Color(0xFFFF3366),
  destructiveForeground: Color(0xFFFFFFFF),
  cyanAccent: kBrandCyan,
  purpleAccent: kBrandPurple,
  cardSurface: Color(0xFFFFFFFF),
  cardBorder: Color(0xFFE5E7EB),
);

const AnimedivesColors darkAnimedivesColors = AnimedivesColors(
  mutedForeground: Color(0xFF9CA3AF),
  border: Color(0xFF22222E),
  input: Color(0xFF14141B),
  accent: Color(0xFF00E5FF),
  accentForeground: Color(0xFF000000),
  destructive: Color(0xFFFF3366),
  destructiveForeground: Color(0xFFFFFFFF),
  cyanAccent: kBrandCyan,
  purpleAccent: kBrandPurple,
  cardSurface: Color(0xDD121218),
  cardBorder: Color(0x3300E5FF),
);

const AnimedivesColors _lightAnimedives = lightAnimedivesColors;
const AnimedivesColors _darkAnimedives = darkAnimedivesColors;


/// Applies Bricolage Grotesque typography with crisp modern metrics.
TextTheme _bricolage(TextTheme base) =>
    GoogleFonts.bricolageGrotesqueTextTheme(base);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF8F9FD),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF0A0A0C),
    onPrimary: const Color(0xFFFFFFFF),
    secondary: const Color(0xFF6366F1),
    onSecondary: const Color(0xFFFFFFFF),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF0F172A),
    surfaceContainerHighest: const Color(0xFFF1F5F9),
    error: kBrandNeonCrimson,
    onError: const Color(0xFFFFFFFF),
    outline: const Color(0xFFCBD5E1),
    outlineVariant: const Color(0xFFE2E8F0),
    inverseSurface: const Color(0xFF0A0A0C),
    inversePrimary: const Color(0xFFFFFFFF),
  ),
  extensions: const <ThemeExtension<dynamic>>[_lightAnimedives],
  textTheme: _bricolage(Typography.material2021().black),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Color(0xFF0F172A),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0A0A0C),
      foregroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: const Color(0xFFFFFFFF),
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
  // Deep AMOLED Obsidian base.
  scaffoldBackgroundColor: kBrandObsidian,
  colorScheme: ColorScheme.dark(
    primary: kBrandCyan,
    onPrimary: const Color(0xFF000000),
    secondary: kBrandPurple,
    onSecondary: const Color(0xFF000000),
    surface: const Color(0xFF101015),
    onSurface: const Color(0xFFFFFFFF),
    surfaceContainerHighest: const Color(0xFF161620),
    error: kBrandNeonCrimson,
    onError: const Color(0xFFFFFFFF),
    outline: const Color(0xFF262635),
    outlineVariant: const Color(0xFF333345),
    inverseSurface: const Color(0xFFFFFFFF),
    inversePrimary: const Color(0xFF000000),
  ),
  extensions: const <ThemeExtension<dynamic>>[_darkAnimedives],
  textTheme: _bricolage(Typography.material2021().white),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Color(0xFFFFFFFF),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kBrandCyan,
      foregroundColor: const Color(0xFF000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: const Color(0xFF14141B),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  ),
);
