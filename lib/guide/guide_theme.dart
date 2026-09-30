import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Light, Dark, or System. System is the default and follows the phone.
enum GuideAppearance { light, dark, system }

GuideAppearance guideAppearanceFromStore(String? value) {
  switch (value) {
    case 'light':
      return GuideAppearance.light;
    case 'dark':
      return GuideAppearance.dark;
    default:
      return GuideAppearance.system;
  }
}

String? guideAppearanceStoreValue(GuideAppearance appearance) {
  switch (appearance) {
    case GuideAppearance.light:
      return 'light';
    case GuideAppearance.dark:
      return 'dark';
    case GuideAppearance.system:
      return null;
  }
}

Brightness guideResolvedBrightness(
  GuideAppearance appearance,
  Brightness platform,
) {
  switch (appearance) {
    case GuideAppearance.light:
      return Brightness.light;
    case GuideAppearance.dark:
      return Brightness.dark;
    case GuideAppearance.system:
      return platform;
  }
}

/// The appearance chosen on the Person page. Redesigned pages listen to it.
class GuideAppearanceController extends ChangeNotifier {
  GuideAppearanceController._();

  static final instance = GuideAppearanceController._();

  GuideAppearance appearance = GuideAppearance.system;

  void apply(GuideAppearance next) {
    if (appearance == next) return;
    appearance = next;
    notifyListeners();
  }

  void resetForTest() {
    appearance = GuideAppearance.system;
    notifyListeners();
  }
}

/// The saved choice, or System when preferences are not ready.
GuideAppearance storedGuideAppearance() {
  if (!Prefs.ready()) return GuideAppearance.system;
  return guideAppearanceFromStore(Prefs.getString(keyGuideTheme, ''));
}

Future<void> saveGuideAppearance(GuideAppearance appearance) async {
  GuideAppearanceController.instance.apply(appearance);
  final stored = guideAppearanceStoreValue(appearance);
  if (stored == null) {
    await Prefs.remove(keyGuideTheme);
  } else {
    await Prefs.setString(keyGuideTheme, stored);
  }
}

/// Field-guide colors, shared with the website mockup.
///
/// Static members are the light palette. Dark pages read [GuideColors.of].
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

/// Light and dark field-guide colors. Dark follows `.glass.dk` in the mockup.
@immutable
class GuideColors extends ThemeExtension<GuideColors> {
  final Color paper;
  final Color paper2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color rule;
  final Color madder;
  final Color moss;
  final Color gold;
  final Color cream;

  /// Filled moss controls: camera card, month chips, selected filters.
  final Color mossFill;

  /// Filled madder marks: the key stepper.
  final Color madderFill;

  /// Text on an ink surface, such as the photo/plate switch.
  final Color onInk;

  /// Label on the camera card. The mockup keeps this cream in both themes.
  final Color onMoss;
  final Color body;
  final Color wash;
  final Color photoWell;
  final Color plateWell;
  final Brightness brightness;

  const GuideColors({
    required this.paper,
    required this.paper2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.rule,
    required this.madder,
    required this.moss,
    required this.gold,
    required this.cream,
    required this.mossFill,
    required this.madderFill,
    required this.onInk,
    required this.onMoss,
    required this.body,
    required this.wash,
    required this.photoWell,
    required this.plateWell,
    required this.brightness,
  });

  static const light = GuideColors(
    paper: GuidePalette.paper,
    paper2: GuidePalette.paper2,
    ink: GuidePalette.ink,
    ink2: GuidePalette.ink2,
    ink3: GuidePalette.ink3,
    rule: GuidePalette.rule,
    madder: GuidePalette.madder,
    moss: GuidePalette.moss,
    gold: GuidePalette.gold,
    cream: GuidePalette.cream,
    mossFill: GuidePalette.moss,
    madderFill: GuidePalette.madder,
    onInk: Colors.white,
    onMoss: GuidePalette.paper,
    body: Color(0xFF2C261F),
    wash: Color(0xEBFFFDF8),
    photoWell: Color(0xFFE6DFCF),
    plateWell: Color(0xFFEFE6D3),
    brightness: Brightness.light,
  );

  static const dark = GuideColors(
    paper: Color(0xFF15120E),
    paper2: Color(0xFF211C16),
    ink: Color(0xFFEEE6D6),
    ink2: Color(0xFFC2B7A3),
    ink3: Color(0xFF9C9180),
    rule: Color(0xFF3A332A),
    madder: Color(0xFFE08A70),
    moss: Color(0xFF9FBEA5),
    gold: Color(0xFFD0A57A),
    cream: Color(0xFF1F1A15),
    mossFill: Color(0xFF4A6652),
    madderFill: Color(0xFFA4493A),
    onInk: Color(0xFF15120E),
    onMoss: GuidePalette.paper,
    body: Color(0xFFDED5C4),
    wash: Color(0xE61F1A15),
    photoWell: Color(0xFF332D25),
    plateWell: Color(0xFFEFE6D3),
    brightness: Brightness.dark,
  );

  static GuideColors forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  /// The page theme when one is set, otherwise the phone's appearance.
  static GuideColors of(BuildContext context) {
    final themed = Theme.of(context).extension<GuideColors>();
    if (themed != null) return themed;
    final platform = MediaQuery.maybeOf(context)?.platformBrightness;
    return forBrightness(platform ?? Brightness.light);
  }

  bool get isDark => brightness == Brightness.dark;

  @override
  GuideColors copyWith({
    Color? paper,
    Color? paper2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? rule,
    Color? madder,
    Color? moss,
    Color? gold,
    Color? cream,
    Color? mossFill,
    Color? madderFill,
    Color? onInk,
    Color? onMoss,
    Color? body,
    Color? wash,
    Color? photoWell,
    Color? plateWell,
    Brightness? brightness,
  }) {
    return GuideColors(
      paper: paper ?? this.paper,
      paper2: paper2 ?? this.paper2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      rule: rule ?? this.rule,
      madder: madder ?? this.madder,
      moss: moss ?? this.moss,
      gold: gold ?? this.gold,
      cream: cream ?? this.cream,
      mossFill: mossFill ?? this.mossFill,
      madderFill: madderFill ?? this.madderFill,
      onInk: onInk ?? this.onInk,
      onMoss: onMoss ?? this.onMoss,
      body: body ?? this.body,
      wash: wash ?? this.wash,
      photoWell: photoWell ?? this.photoWell,
      plateWell: plateWell ?? this.plateWell,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  GuideColors lerp(GuideColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GuideColors(
      paper: mix(paper, other.paper),
      paper2: mix(paper2, other.paper2),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      ink3: mix(ink3, other.ink3),
      rule: mix(rule, other.rule),
      madder: mix(madder, other.madder),
      moss: mix(moss, other.moss),
      gold: mix(gold, other.gold),
      cream: mix(cream, other.cream),
      mossFill: mix(mossFill, other.mossFill),
      madderFill: mix(madderFill, other.madderFill),
      onInk: mix(onInk, other.onInk),
      onMoss: mix(onMoss, other.onMoss),
      body: mix(body, other.body),
      wash: mix(wash, other.wash),
      photoWell: mix(photoWell, other.photoWell),
      plateWell: mix(plateWell, other.plateWell),
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GuideColors &&
        other.paper == paper &&
        other.paper2 == paper2 &&
        other.ink == ink &&
        other.ink2 == ink2 &&
        other.ink3 == ink3 &&
        other.rule == rule &&
        other.madder == madder &&
        other.moss == moss &&
        other.gold == gold &&
        other.cream == cream &&
        other.mossFill == mossFill &&
        other.madderFill == madderFill &&
        other.onInk == onInk &&
        other.onMoss == onMoss &&
        other.body == body &&
        other.wash == wash &&
        other.photoWell == photoWell &&
        other.plateWell == plateWell &&
        other.brightness == brightness;
  }

  @override
  int get hashCode => Object.hash(
        paper,
        paper2,
        ink,
        ink2,
        ink3,
        rule,
        madder,
        moss,
        gold,
        cream,
        mossFill,
        madderFill,
        onInk,
        onMoss,
        body,
        wash,
        photoWell,
        plateWell,
        brightness,
      );
}

class GuideType {
  static const serif = 'Fraunces';
  static const sans = 'Source Sans 3';

  static TextStyle wordmark(GuideColors colors) => TextStyle(
        fontFamily: serif,
        fontWeight: FontWeight.w500,
        fontSize: 21,
        letterSpacing: -0.4,
        color: colors.ink,
        height: 1.1,
      );

  static TextStyle section(GuideColors colors) => TextStyle(
        fontFamily: serif,
        fontWeight: FontWeight.w500,
        fontSize: 18,
        color: colors.ink,
        height: 1.15,
      );

  static TextStyle question(GuideColors colors) => TextStyle(
        fontFamily: serif,
        fontWeight: FontWeight.w500,
        fontSize: 25,
        letterSpacing: -0.4,
        color: colors.ink,
        height: 1.1,
      );

  static TextStyle eyebrow(GuideColors colors) => TextStyle(
        fontFamily: sans,
        fontSize: 11,
        letterSpacing: 1,
        fontWeight: FontWeight.w600,
        color: colors.ink3,
      );

  static TextStyle latin(GuideColors colors) => TextStyle(
        fontFamily: serif,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        color: colors.ink,
      );
}

ThemeData guideTheme([Brightness brightness = Brightness.light]) {
  final colors = GuideColors.forBrightness(brightness);
  final scheme = brightness == Brightness.dark
      ? ColorScheme.dark(
          primary: colors.moss,
          onPrimary: Colors.white,
          secondary: colors.madder,
          onSecondary: Colors.white,
          surface: colors.paper,
          onSurface: colors.ink,
        )
      : ColorScheme.light(
          primary: colors.moss,
          onPrimary: Colors.white,
          secondary: colors.madder,
          onSecondary: Colors.white,
          surface: colors.paper,
          onSurface: colors.ink,
        );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.paper,
    canvasColor: colors.paper,
    fontFamily: GuideType.sans,
    colorScheme: scheme,
    splashColor: colors.moss.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,
    extensions: [colors],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: colors.ink,
      displayColor: colors.ink,
      fontFamily: GuideType.sans,
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
  );
}

/// Applies the field-guide theme. System follows the phone. Light and Dark
/// are the choice saved on the Person page.
class GuideTheme extends StatelessWidget {
  final Widget child;
  final Color Function(GuideColors colors)? navigationColor;

  /// Overrides the saved choice. Tests use this.
  final GuideAppearance? appearance;

  const GuideTheme({
    super.key,
    required this.child,
    this.navigationColor,
    this.appearance,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GuideAppearanceController.instance,
      builder: (context, child) {
        final chosen =
            appearance ?? GuideAppearanceController.instance.appearance;
        final brightness = guideResolvedBrightness(
          chosen,
          MediaQuery.platformBrightnessOf(context),
        );
        final colors = GuideColors.forBrightness(brightness);
        final overlay = brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;
        return Theme(
          data: guideTheme(brightness),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor:
                  navigationColor?.call(colors) ?? colors.paper,
            ),
            child: child!,
          ),
        );
      },
      child: child,
    );
  }
}

String guideCap(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
