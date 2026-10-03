import 'package:flutter/material.dart';

const kFontFamily = 'Inter';
const s8 = 8.0;
const s16 = 16.0;
const s24 = 24.0;
const s32 = 32.0;

const harmonyBackground = Color(0xFFFFFFFF);
const harmonySurface = Color(0xFFF5F5F5);
const harmonyPrimary = Color(0xFF000000);
const harmonySecondary = Color(0xFF4A4A4A);
const harmonyBody = Color(0xFF111111);
const harmonyBorder = Color(0xFFCCCCCC);

TextTheme _harmonyTextTheme() {
  return const TextTheme(
    displayLarge: TextStyle(
      fontSize: 36,
      height: 1.05,
      fontWeight: FontWeight.w800,
      color: harmonyBody,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: harmonyBody,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: harmonyBody,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w400,
      color: harmonyBody,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w300,
      color: harmonySecondary,
    ),
  );
}

ThemeData buildHarmonyTheme() {
  final textTheme = _harmonyTextTheme();
  const scheme = ColorScheme.light(
    primary: harmonyPrimary,
    onPrimary: Colors.white,
    secondary: harmonySecondary,
    onSecondary: Colors.white,
    surface: harmonyBackground,
    onSurface: harmonyBody,
    outline: harmonyBorder,
  );
  final outlineShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(4),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.light,
    scaffoldBackgroundColor: harmonyBackground,
    textTheme: textTheme,
    fontFamily: kFontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: harmonyBackground,
      foregroundColor: harmonyBody,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: harmonySurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: outlineShape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: harmonyPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: s16, vertical: s8),
        shape: outlineShape,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: harmonyBody,
        side: const BorderSide(color: harmonyBorder),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: s16, vertical: s8),
        shape: outlineShape,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: harmonyBody,
        padding: const EdgeInsets.symmetric(horizontal: s8, vertical: s8),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: harmonyBody,
        shape: outlineShape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: harmonySurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: s16, vertical: s8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: harmonyBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: harmonyBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: harmonyPrimary, width: 2),
      ),
      labelStyle: const TextStyle(fontSize: 14, color: harmonySecondary),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: harmonySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: harmonyBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: harmonyBorder),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? harmonyPrimary
            : harmonyBorder,
      ),
      trackOutlineColor: WidgetStateProperty.all(harmonyBorder),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: harmonyPrimary,
      inactiveTrackColor: harmonyBorder,
      thumbColor: Colors.white,
      overlayColor: Colors.transparent,
      trackHeight: 2,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: harmonyBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: harmonyBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: outlineShape.copyWith(
        side: const BorderSide(color: harmonyBorder),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: harmonyPrimary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      elevation: 0,
      shape: outlineShape,
      behavior: SnackBarBehavior.floating,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: harmonyBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: outlineShape.copyWith(
        side: const BorderSide(color: harmonyBorder),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: harmonyBorder,
      thickness: 1,
      space: 1,
    ),
  );
}
