// hext_design_system.dart
// Centralized design system for HEXT
import 'package:flutter/material.dart';

class HextColors {
  // Institutional
  static const Color verdePrincipal = Color(0xFF17726D); // #17726D
  static const Color dorado = Color(0xFFCCBA86); // #CCBA86

  // Neutrals
  static const Color blanco = Colors.white;
  static const Color fondoSuave = Color(0xFFF5F7FA);
  static const Color fondoTarjeta = Color(0xFFF7F8FA);
  static const Color bordeSuave = Color(0xFFDCE3EA);
  static const Color bordeTarjeta = Color(0xFFE3E7EC);
  static const Color textoSecundario = Color(0xFF748096);
  static const Color textoPrincipal = Color(0xFF243247);
  static const Color textoSuave = Color(0xFF5B6474);
  static const Color textoGris = Color(0xFF8A9199);
  static const Color textoGrisOscuro = Color(0xFF5C6370);

  // States (softened)
  static const Color estadoExito = Color(0xFF3BAA8D); // softened green
  static const Color estadoAdvertencia = Color(0xFFE2B13C); // softened yellow
  static const Color estadoError = Color(0xFFE57373); // softened red
  static const Color estadoRojo = Color(0xFFB42318); // legacy, for compatibility
  static const Color estadoAmarillo = Color(0xFF946200); // legacy, for compatibility
}
