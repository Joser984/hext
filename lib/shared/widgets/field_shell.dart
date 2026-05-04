import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

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

  static const double fieldHeight = HextDimens.fieldHeight;
  static const double borderRadius = HextDimens.radiusField;
  static const double borderWidth = 1.2;
  static const double labelSpacing = HextDimens.labelGap;
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

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

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !enabled
        ? HextColors.border
        : error
        ? HextColors.error
        : focused
        ? HextColors.primary
        : HextColors.border;
    final Color backgroundColor = enabled
        ? HextColors.card
        : const Color(0xFFF3F4F6);

    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label != null && label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: labelSpacing),
              child: Text(
                label!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: HextColors.textSecondary,
                ),
              ),
            ),
          Container(
            height: fieldHeight,
            padding: contentPadding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
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
                  color: HextColors.error,
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
