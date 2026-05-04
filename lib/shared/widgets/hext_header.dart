import 'package:flutter/material.dart';
import 'package:hext/shared/widgets/hext_mark.dart';

enum HextHeaderVariant { topBar, sidebar, login }

class HextHeader extends StatelessWidget {
  const HextHeader({
    super.key,
    this.variant = HextHeaderVariant.topBar,
    this.showBackground = false,
    this.showWordmark = true,
  });

  final HextHeaderVariant variant;
  final bool showBackground;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final bool dark = variant != HextHeaderVariant.login;
    final Color foreground = dark ? Colors.white : const Color(0xFF17726D);
    final double markSize = switch (variant) {
      HextHeaderVariant.topBar => 24,
      HextHeaderVariant.sidebar => 28,
      HextHeaderVariant.login => 48,
    };
    final double fontSize = switch (variant) {
      HextHeaderVariant.topBar => 18,
      HextHeaderVariant.sidebar => 24,
      HextHeaderVariant.login => 28,
    };
    final double spacing = switch (variant) {
      HextHeaderVariant.topBar => 10,
      HextHeaderVariant.sidebar => 12,
      HextHeaderVariant.login => 14,
    };

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        HextMark(
          size: markSize,
          variant: HextMarkVariant.transparentMark,
          color: foreground,
        ),
        if (showWordmark) ...<Widget>[
          SizedBox(width: spacing),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: foreground,
                letterSpacing: variant == HextHeaderVariant.topBar ? 1.1 : 1.4,
                height: 1,
              ),
              children: const <TextSpan>[
                TextSpan(text: 'HE'),
                TextSpan(
                  text: 'X',
                  style: TextStyle(color: Color(0xFFCCBA86)),
                ),
                TextSpan(text: 'T'),
              ],
            ),
          ),
        ],
      ],
    );

    if (!showBackground) {
      return content;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0x14000000) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: content,
      ),
    );
  }
}
