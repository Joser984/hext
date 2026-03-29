import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final Color primary = Color(0xFF223A5E); // Azul grafito
  static final Color accent = Color(0xFF00B4D8); // Cian medido
  static final Color background = Color(0xFFF6F9FB); // Fondo claro frío

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
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: accent,
    ),
  );
}
