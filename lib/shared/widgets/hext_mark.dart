import 'package:flutter/material.dart';

enum HextMarkVariant { fullIcon, transparentMark }

class HextMark extends StatelessWidget {
  const HextMark({
    super.key,
    this.size = 72,
    this.variant = HextMarkVariant.fullIcon,
    this.color,
    this.showShadow = false,
    this.borderRadius,
  });

  static const String fullIconAssetPath =
      'assets/images/app_icon/hext_logo_official.png';
  static const String transparentMarkAssetPath =
      'assets/images/app_icon/hext_logo_transparent.png';

  final double size;
  final HextMarkVariant variant;
  final Color? color;
  final bool showShadow;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bool isFullIcon = variant == HextMarkVariant.fullIcon;
    final BorderRadius resolvedBorderRadius =
        borderRadius ?? BorderRadius.circular(size * 0.24);

    final Widget image = Image.asset(
      isFullIcon ? fullIconAssetPath : transparentMarkAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      color: isFullIcon ? null : color,
      colorBlendMode: BlendMode.srcIn,
    );

    if (!isFullIcon) {
      return SizedBox(
        width: size,
        height: size,
        child: image,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: resolvedBorderRadius,
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}
