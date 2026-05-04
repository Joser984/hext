import 'package:flutter/material.dart';
import 'package:hext/core/theme/hext_ui_tokens.dart';
import 'package:hext/shared/widgets/hext_card.dart';

class FilterShell extends StatelessWidget {
  const FilterShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    this.actions,
  });

  final String title;
  final String subtitle;
  final Widget fields;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return HextCard(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: HextTextStyles.subsectionTitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: HextTextStyles.secondary.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          fields,
          if (actions != null) ...<Widget>[
            const SizedBox(height: 8),
            actions!,
          ],
        ],
      ),
    );
  }
}
