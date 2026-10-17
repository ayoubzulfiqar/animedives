import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animedives/themes.dart';

void main() {
  testWidgets(
    'Pure Monochrome Minimalist theme provides AMOLED tokens and extensions',
    (tester) async {
      expect(kMonochromeBlack, const Color(0xFF000000));
      expect(kMonochromeWhite, const Color(0xFFFFFFFF));
      expect(kBrandObsidian, const Color(0xFF000000));

      final dark = darkTheme;
      expect(dark.scaffoldBackgroundColor, const Color(0xFF000000));
      final ext = dark.extension<AnimedivesColors>();
      expect(ext, isNotNull);
      expect(ext!.cyanAccent, kBrandCyan);
      expect(ext.purpleAccent, kBrandPurple);
      expect(ext.cardSurface, isNotNull);
      expect(ext.cardBorder, isNotNull);
    },
  );

  test('animedivesCyberGradient produces monochrome linear gradient', () {
    const gradient = animedivesCyberGradient;
    expect(gradient.colors, [const Color(0xFFFFFFFF), const Color(0xFFA1A1AA)]);
  });
}
