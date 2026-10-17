import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animedives/themes.dart';

void main() {
  testWidgets(
    'Electric Cyber Glassmorphism theme provides brand tokens and extensions',
    (tester) async {
      expect(kBrandCyan, const Color(0xFF00E5FF));
      expect(kBrandPurple, const Color(0xFFB388FF));
      expect(kBrandObsidian, const Color(0xFF08080A));

      final dark = darkTheme;
      expect(dark.scaffoldBackgroundColor, const Color(0xFF08080A));
      final ext = dark.extension<AnimedivesColors>();
      expect(ext, isNotNull);
      expect(ext!.cyanAccent, kBrandCyan);
      expect(ext.purpleAccent, kBrandPurple);
      expect(ext.cardSurface, isNotNull);
      expect(ext.cardBorder, isNotNull);
    },
  );

  test('animedivesCyberGradient produces cyan to purple linear gradient', () {
    const gradient = animedivesCyberGradient;
    expect(gradient.colors, [kBrandCyan, kBrandPurple]);
  });
}
