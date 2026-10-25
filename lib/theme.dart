// 흑백 테마 — 색은 상품 사진에만 남기고 UI는 검정·회색·흰색만 쓴다.
// 상태(원함·구매함)도 색이 아니라 채움/테두리로 구분한다. (P08 미니멀 · P04 일관성)
import 'package:flutter/material.dart';

abstract final class Gp {
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF6B6B6B);
  static const faint = Color(0xFFA3A3A3);
  static const line = Color(0xFFE6E6E6);
  static const soft = Color(0xFFF0F0EE);

  /// 페이지 바탕: 아주 옅은 따뜻한 회백색 — 흰 버튼이 떠 보이게
  static const bg = Color(0xFFF7F7F5);

  /// 카드·시트 면
  static const panel = Color(0xFFFFFFFF);
  static const danger = Color(0xFFC0392B);
  static const radius = 12.0;

  /// 떠 있는 흰 버튼(아바타 · + · 채널 타일): 흰→옅은 회색 그라데이션 + 부드러운 그림자
  static BoxDecoration raised({BoxShape shape = BoxShape.rectangle, double radius = 14}) =>
      BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEDEDEB)],
        ),
        border: Border.all(color: const Color(0xE6FFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      );
}

ThemeData buildGpTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Gp.ink,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    primary: Gp.ink,
    onPrimary: Colors.white,
    surface: Gp.bg,
    onSurface: Gp.ink,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Gp.bg,
    dividerColor: Gp.line,
    splashFactory: NoSplash.splashFactory,
    textTheme: base.textTheme.apply(bodyColor: Gp.ink, displayColor: Gp.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: Gp.bg,
      foregroundColor: Gp.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Gp.ink, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    dividerTheme: const DividerThemeData(color: Gp.line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Gp.ink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gp.radius)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Gp.ink,
        side: const BorderSide(color: Gp.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gp.radius)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Gp.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Gp.soft,
      isDense: true,
      hintStyle: const TextStyle(color: Gp.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Gp.radius),
        borderSide: BorderSide.none,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Gp.panel,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Gp.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Gp.ink,
      actionTextColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Gp.bg,
      indicatorColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Gp.ink : Gp.faint,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Gp.ink : Gp.faint),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Gp.bg,
      indicatorColor: Gp.soft,
      selectedIconTheme: IconThemeData(color: Gp.ink),
      unselectedIconTheme: IconThemeData(color: Gp.faint),
      selectedLabelTextStyle: TextStyle(color: Gp.ink, fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(color: Gp.faint, fontSize: 12),
    ),
  );
}
