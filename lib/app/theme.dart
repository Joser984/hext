import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final Color primary = Color(0xFF223A5E); // Azul grafito
  static final Color accent = Color(0xFF00B4D8); // Cian medido
  static final Color background = Color(0xFFF6F9FB); // Fondo claro frío
  static const double controlHeight = 40;

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: background,
    ),
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.montserratTextTheme(),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, controlHeight),
        maximumSize: const Size(double.infinity, controlHeight),
        alignment: Alignment.center,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, controlHeight),
        maximumSize: const Size(double.infinity, controlHeight),
        alignment: Alignment.center,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, controlHeight),
        maximumSize: const Size(double.infinity, controlHeight),
        alignment: Alignment.center,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, controlHeight),
        alignment: Alignment.center,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: accent,
    ),
  );
}
