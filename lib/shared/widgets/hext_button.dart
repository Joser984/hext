import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

enum HextButtonVariant { primary, secondary, neutral }

class HextButton extends StatelessWidget {
  const HextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HextButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  const HextButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  }) : variant = HextButtonVariant.primary;

  const HextButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  }) : variant = HextButtonVariant.secondary;

  const HextButton.neutral({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  }) : variant = HextButtonVariant.neutral;

  final String label;
  final VoidCallback? onPressed;
  final HextButtonVariant variant;
  final Widget? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              icon!,
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final Widget button = switch (variant) {
      HextButtonVariant.primary => ElevatedButton(
        onPressed: onPressed,
        style: hextPrimaryButtonStyle(),
        child: child,
      ),
      HextButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        style: hextSecondaryButtonStyle(),
        child: child,
      ),
      HextButtonVariant.neutral => OutlinedButton(
        onPressed: onPressed,
        style: hextNeutralButtonStyle(),
        child: child,
      ),
    };

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}