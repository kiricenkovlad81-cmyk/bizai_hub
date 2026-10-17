import 'package:flutter/material.dart';

/// Colour tokens of BizAI Hub: deep steppe-teal rail, sky-teal accent, sun-gold for AI highlights.
@immutable
class Biz extends ThemeExtension<Biz> {
  const Biz({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.sunken,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.accentLine,
    required this.sun,
    required this.sunInk,
    required this.sunSoft,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.violet,
    required this.violetSoft,
    required this.danger,
    required this.dangerSoft,
    required this.ig,
    required this.tg,
    required this.wa,
    required this.chipInk,
    required this.railBg,
    required this.railInk,
    required this.railInk2,
    required this.railHover,
    required this.railActive,
    required this.heroBg,
    required this.heroInk,
    required this.heroInk2,
    required this.heroUp,
  });

  final Color bg, surface, surface2, sunken, line, lineStrong, ink, ink2, ink3;
  final Color accent, accentInk, accentSoft, accentLine, sun, sunInk, sunSoft;
  final Color ok, okSoft, warn, warnSoft, violet, violetSoft, danger, dangerSoft;
  final Color ig, tg, wa, chipInk;
  final Color railBg, railInk, railInk2, railHover, railActive;
  final Color heroBg, heroInk, heroInk2, heroUp;

  static Biz of(BuildContext context) => Theme.of(context).extension<Biz>()!;

  @override
  Biz copyWith() => this;

  @override
  Biz lerp(ThemeExtension<Biz>? other, double t) {
    if (other is! Biz) return this;
    return t < 0.5 ? this : other;
  }
}

const Biz bizLight = Biz(
  bg: Color(0xFFECF1F2),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF5F8F9),
  sunken: Color(0xFFE3EAEC),
  line: Color(0xFFD2DCDF),
  lineStrong: Color(0xFFAFC0C5),
  ink: Color(0xFF0A1A20),
  ink2: Color(0xFF3D5259),
  ink3: Color(0xFF5B7077),
  accent: Color(0xFF0A6A82),
  accentInk: Color(0xFFFFFFFF),
  accentSoft: Color(0xFFDBEDF2),
  accentLine: Color(0xFF9FCEDA),
  sun: Color(0xFFB27600),
  sunInk: Color(0xFF1C1300),
  sunSoft: Color(0xFFFBF0D4),
  ok: Color(0xFF0F7146),
  okSoft: Color(0xFFDAF0E3),
  warn: Color(0xFF955600),
  warnSoft: Color(0xFFFAE8C8),
  violet: Color(0xFF5839AD),
  violetSoft: Color(0xFFE9E3F8),
  danger: Color(0xFFB3202D),
  dangerSoft: Color(0xFFFBE2E4),
  ig: Color(0xFFB4305F),
  tg: Color(0xFF1F6FAE),
  wa: Color(0xFF127F44),
  chipInk: Color(0xFFFFFFFF),
  railBg: Color(0xFF0B252D),
  railInk: Color(0xFFE4EFF1),
  railInk2: Color(0xFF93B1B9),
  railHover: Color(0xFF12343F),
  railActive: Color(0xFF1A4553),
  heroBg: Color(0xFF0B252D),
  heroInk: Color(0xFFF1F7F8),
  heroInk2: Color(0xFF9DBAC1),
  heroUp: Color(0xFF7EE2AF),
);

const Biz bizDark = Biz(
  bg: Color(0xFF071013),
  surface: Color(0xFF0E1A1E),
  surface2: Color(0xFF122227),
  sunken: Color(0xFF0A1519),
  line: Color(0xFF21353C),
  lineStrong: Color(0xFF33505A),
  ink: Color(0xFFE7F0F2),
  ink2: Color(0xFFAEC1C6),
  ink3: Color(0xFF8AA2A9),
  accent: Color(0xFF3DB6D1),
  accentInk: Color(0xFF031519),
  accentSoft: Color(0xFF103038),
  accentLine: Color(0xFF1E5563),
  sun: Color(0xFFF0B43A),
  sunInk: Color(0xFF1C1300),
  sunSoft: Color(0xFF33270B),
  ok: Color(0xFF4ECB8D),
  okSoft: Color(0xFF0E3123),
  warn: Color(0xFFF2B24A),
  warnSoft: Color(0xFF38280B),
  violet: Color(0xFFAC94F4),
  violetSoft: Color(0xFF251D3F),
  danger: Color(0xFFF27C86),
  dangerSoft: Color(0xFF3B1418),
  ig: Color(0xFFE66C9C),
  tg: Color(0xFF5CA9E8),
  wa: Color(0xFF46C680),
  chipInk: Color(0xFF06121A),
  railBg: Color(0xFF0A1619),
  railInk: Color(0xFFE3EEF0),
  railInk2: Color(0xFF86A0A7),
  railHover: Color(0xFF12232A),
  railActive: Color(0xFF173842),
  heroBg: Color(0xFF0F3640),
  heroInk: Color(0xFFEEF7F8),
  heroInk2: Color(0xFF9CC0C8),
  heroUp: Color(0xFF5FD99B),
);

const List<FontFeature> kTabular = <FontFeature>[FontFeature.tabularFigures()];

/// Display face (Unbounded) — only for numbers and the wordmark; Kazakh letters fall back to Onest.
TextStyle tDisplay(double size, Color color) => TextStyle(
      fontFamily: 'Unbounded',
      fontFamilyFallback: const <String>['Onest'],
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -size * 0.025,
      height: 1.05,
      fontFeatures: kTabular,
    );

TextStyle tMono(double size, Color color, {FontWeight weight = FontWeight.w500, double height = 1.3}) => TextStyle(
      fontFamily: 'JetBrainsMono',
      fontFamilyFallback: const <String>['Onest'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFeatures: kTabular,
    );

TextStyle tBody(double size, Color color, {FontWeight weight = FontWeight.w400, double height = 1.42}) => TextStyle(
      fontFamily: 'Onest',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

ThemeData buildTheme(Brightness brightness) {
  final b = brightness == Brightness.light ? bizLight : bizDark;
  final scheme = ColorScheme.fromSeed(seedColor: b.accent, brightness: brightness).copyWith(
    primary: b.accent,
    onPrimary: b.accentInk,
    secondary: b.sun,
    onSecondary: b.sunInk,
    surface: b.surface,
    onSurface: b.ink,
    error: b.danger,
    outline: b.lineStrong,
    outlineVariant: b.line,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: b.bg,
    canvasColor: b.surface,
    fontFamily: 'Onest',
    dividerColor: b.line,
    extensions: <ThemeExtension<dynamic>>[b],
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
    textSelectionTheme: TextSelectionThemeData(cursorColor: b.accent, selectionColor: b.accentLine),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: b.surface2,
      hintStyle: tBody(14, b.ink3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: b.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: b.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: b.accent, width: 1.4)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: b.accent,
        foregroundColor: b.accentInk,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: tBody(14, b.accentInk, weight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: b.ink,
        backgroundColor: b.surface,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: BorderSide(color: b.lineStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: tBody(14, b.ink, weight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? b.surface : b.surface),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? b.ok : b.lineStrong),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: b.ink, contentTextStyle: tBody(14, b.surface)),
  );
}
