import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

Future<T?> showHextDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: HextColors.overlay,
    builder: builder,
  );
}

class HextModal extends StatelessWidget {
  const HextModal({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.onClose,
    this.maxWidth = 540,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: HextColors.card,
            borderRadius: BorderRadius.circular(HextDimens.radiusModal),
            border: Border.all(color: HextColors.border),
          ),
          padding: const EdgeInsets.all(HextDimens.paddingModal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              HextModalHeader(
                title: title,
                subtitle: subtitle,
                onClose: onClose,
              ),
              const SizedBox(height: 20),
              child,
              if (actions != null && actions!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 20),
                HextModalActions(children: actions!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HextModalHeader extends StatelessWidget {
  const HextModalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: HextTextStyles.pageTitle),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(subtitle!, style: HextTextStyles.secondary),
              ],
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: HextColors.textSecondary,
            splashRadius: 18,
          ),
      ],
    );
  }
}

class HextModalActions extends StatelessWidget {
  const HextModalActions({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 12),
          Flexible(child: children[i]),
        ],
      ],
    );
  }
}