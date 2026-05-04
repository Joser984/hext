import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';

class HextPageShell extends StatelessWidget {
  const HextPageShell({
    super.key,
    required this.builder,
    this.maxWidth = HextDimens.pageMaxWidth,
    this.desktopHorizontalPadding = 24,
    this.mobileHorizontalPadding = 16,
  });

  final Widget Function(BuildContext context, BoxConstraints constraints)
  builder;
  final double maxWidth;
  final double desktopHorizontalPadding;
  final double mobileHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HextColors.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double horizontalPadding = constraints.maxWidth >= 900
                ? desktopHorizontalPadding
                : mobileHorizontalPadding;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: SizedBox(
                  width: constraints.maxWidth < maxWidth
                      ? constraints.maxWidth
                      : maxWidth,
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints innerConstraints,
                      ) {
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            24,
                            horizontalPadding,
                            24,
                          ),
                          child: builder(context, innerConstraints),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HextModuleHeader extends StatelessWidget {
  const HextModuleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.tabs,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool canUseTrailingRow = trailing != null &&
            constraints.maxWidth >= 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (canUseTrailingRow)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _HeaderText(title: title, subtitle: subtitle)),
                  const SizedBox(width: 16),
                  trailing!,
                ],
              )
            else ...<Widget>[
              _HeaderText(title: title, subtitle: subtitle),
              if (trailing != null) ...<Widget>[
                const SizedBox(height: 12),
                trailing!,
              ],
            ],
            if (tabs != null) ...<Widget>[
              const SizedBox(height: 12),
              tabs!,
            ],
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: HextColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: HextColors.textMuted,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class HextPageHeader extends HextModuleHeader {
  const HextPageHeader({
    super.key,
    required super.title,
    required super.subtitle,
    super.trailing,
    super.tabs,
  });
}
