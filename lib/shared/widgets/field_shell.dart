import 'package:flutter/material.dart';

/// FieldShell es el contenedor base puramente visual para todos los campos reutilizables.
/// Centraliza altura, borde, radio, fondo, padding, tipografía, separación label-campo y estados visuales.
/// No contiene lógica de input ni dropdown; solo estructura visual y de estado.
class FieldShell extends StatelessWidget {
  final String? label;
  final bool focused;
  final bool error;
  final bool enabled;
  final String? errorText;
  final Widget child;
  final EdgeInsetsGeometry? margin;

  static const double fieldHeight = 40; // Más compacto
  static const double borderRadius = 10;
  static const double borderWidth = 1.4;
  static const double labelSpacing = 3; // Menor separación label-campo
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 7,
  ); // Menos padding

  const FieldShell({
    super.key,
    this.label,
    this.focused = false,
    this.error = false,
    this.enabled = true,
    this.errorText,
    required this.child,
    this.margin,
  });

  Color get _borderColor {
    if (!enabled) return const Color(0xFFE0E3E7);
    if (error) return const Color(0xFFEF4444);
    if (focused) return const Color(0xFF06B6D4);
    return const Color(0xFFE0E3E7);
  }

  Color get _backgroundColor =>
      enabled ? const Color(0xFFF7F8FA) : const Color(0xFFF1F1F1);

  TextStyle get _labelStyle => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF6B7280),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null && label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: labelSpacing),
              child: Text(label!, style: _labelStyle),
            ),
          Container(
            height: fieldHeight,
            padding: contentPadding,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: _borderColor,
                width: error ? borderWidth : 1.0,
              ),
            ),
            child: child,
          ),
          if (error && errorText != null && errorText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 2),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
