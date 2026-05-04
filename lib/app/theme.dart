import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

class AppTheme {
  static const Color primary = HextColors.primary;
  static const Color accent = HextColors.secondary;
  static const Color softBackground = HextColors.background;
  static const Color textPrimary = HextColors.textPrimary;
  static const Color textSecondary = HextColors.textSecondary;
  static const Color border = HextColors.border;
  static const Color surfaceBase = HextColors.card;
  static const double controlHeight = 40;

  static final ThemeData light = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surfaceBase,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
    ),
    scaffoldBackgroundColor: softBackground,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    cardTheme: CardThemeData(
      color: surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
      elevation: 0,
      margin: EdgeInsets.all(8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceBase,
      foregroundColor: textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    dividerColor: border,
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HextColors.sidebar,
        foregroundColor: Colors.white,
        disabledBackgroundColor: HextColors.borderSoft,
        disabledForegroundColor: HextColors.textMuted,
        overlayColor: HextColors.primarySoft,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, controlHeight),
        maximumSize: const Size(double.infinity, controlHeight),
        alignment: Alignment.center,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        backgroundColor: surfaceBase,
        disabledForegroundColor: HextColors.textMuted,
        overlayColor: HextColors.primarySoft,
        side: const BorderSide(color: border),
        minimumSize: const Size(0, controlHeight),
        maximumSize: const Size(double.infinity, controlHeight),
        alignment: Alignment.center,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HextColors.sidebar,
        foregroundColor: Colors.white,
        disabledBackgroundColor: HextColors.borderSoft,
        disabledForegroundColor: HextColors.textMuted,
        overlayColor: HextColors.primarySoft,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, controlHeight),
        maximumSize: const Size(double.infinity, controlHeight),
        alignment: Alignment.center,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        disabledForegroundColor: HextColors.textMuted,
        overlayColor: HextColors.primarySoft,
        minimumSize: const Size(0, controlHeight),
        alignment: Alignment.center,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      buttonColor: primary,
    ),
  );
}
