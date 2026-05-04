import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

class HextCard extends StatelessWidget {
  const HextCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HextDimens.paddingCard),
    this.margin,
    this.width,
    this.color,
    this.borderColor,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? HextColors.card,
        borderRadius: BorderRadius.circular(
          borderRadius ?? HextDimens.radiusCard,
        ),
        border: Border.all(
          color: borderColor ?? HextColors.border,
          width: 1,
        ),
        boxShadow: HextShadows.card,
      ),
      child: child,
    );
  }
}