import 'package:flutter/material.dart';
import 'package:hext/shared/widgets/hext_mark.dart';

class HextLogo extends StatelessWidget {
  const HextLogo({
    super.key,
    this.size = 72,
    this.color = const Color(0xFF17726D),
    this.variant = HextMarkVariant.transparentMark,
    this.showShadow = false,
    this.borderRadius,
  });

  static const String assetPath = HextMark.transparentMarkAssetPath;

  final double size;
  final Color color;
  final HextMarkVariant variant;
  final bool showShadow;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return HextMark(
      size: size,
      variant: variant,
      color: variant == HextMarkVariant.transparentMark ? color : null,
      showShadow: showShadow,
      borderRadius: borderRadius,
    );
  }
}
