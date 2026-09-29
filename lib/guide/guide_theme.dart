import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Field-guide colors, shared with the website.
class GuidePalette {
  static const paper = Color(0xFFF3EEE4);
  static const paper2 = Color(0xFFE9E2D3);
  static const ink = Color(0xFF1A1612);
  static const ink2 = Color(0xFF5A5248);
  static const ink3 = Color(0xFF6E6659);
  static const rule = Color(0xFFD0C6B2);
  static const madder = Color(0xFF8E3B2A);
  static const moss = Color(0xFF3E5344);
  static const gold = Color(0xFF85603C);
  static const cream = Color(0xFFFFFDF8);

  static const swatchWhite = Color(0xFFF8F5EE);
  static const swatchYellow = Color(0xFFE4BB3B);
  static const swatchRed = Color(0xFFC4566B);
  static const swatchBlue = Color(0xFF5B62A8);
  static const swatchGreen = Color(0xFF6F7D4C);
}

Color guideSwatchColor(String id) {
  switch (id) {
    case '1':
      return GuidePalette.swatchWhite;
    case '2':
      return GuidePalette.swatchYellow;
    case '3':
      return GuidePalette.swatchRed;
    case '4':
      return GuidePalette.swatchBlue;
    case '5':
      return GuidePalette.swatchGreen;
    default:
      return GuidePalette.cream;
  }
}

class GuideType {
  static const serif = 'Fraunces';
  static const sans = 'Source Sans 3';

  static const wordmark = TextStyle(
    fontFamily: serif,
    fontWeight: FontWeight.w500,
    fontSize: 21,
    letterSpacing: -0.4,
    color: GuidePalette.ink,
    height: 1.1,
  );

  static const section = TextStyle(
    fontFamily: serif,
    fontWeight: FontWeight.w500,
    fontSize: 18,
    color: GuidePalette.ink,
    height: 1.15,
  );

  static const question = TextStyle(
    fontFamily: serif,
    fontWeight: FontWeight.w500,
    fontSize: 25,
    letterSpacing: -0.4,
    color: GuidePalette.ink,
    height: 1.1,
  );

  static const eyebrow = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    letterSpacing: 1,
    fontWeight: FontWeight.w600,
    color: GuidePalette.ink3,
  );

  static const latin = TextStyle(
    fontFamily: serif,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    color: GuidePalette.ink,
  );
}

ThemeData guideTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: GuidePalette.paper,
    canvasColor: GuidePalette.paper,
    fontFamily: GuideType.sans,
    colorScheme: const ColorScheme.light(
      primary: GuidePalette.moss,
      onPrimary: Colors.white,
      secondary: GuidePalette.madder,
      surface: GuidePalette.paper,
      onSurface: GuidePalette.ink,
    ),
    splashColor: const Color(0x143E5344),
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: GuidePalette.ink,
      displayColor: GuidePalette.ink,
      fontFamily: GuideType.sans,
    ),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
  );
}

String guideCap(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
