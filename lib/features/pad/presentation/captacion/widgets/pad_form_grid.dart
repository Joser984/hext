import 'package:flutter/material.dart';

import 'pad_form_styles.dart';

class PadFormGridItem {
  const PadFormGridItem({
    required this.child,
    this.span = 1,
  }) : assert(span > 0 && span <= 4);

  final Widget child;
  final int span;
}

class PadFormGrid extends StatelessWidget {
  const PadFormGrid({
    super.key,
    required this.children,
    this.desktopBreakpoint = 1180,
    this.tabletBreakpoint = 760,
    this.desktopColumns = 4,
    this.tabletColumns = 2,
    this.alignment = WrapAlignment.center,
  });

  final List<PadFormGridItem> children;
  final double desktopBreakpoint;
  final double tabletBreakpoint;
  final int desktopColumns;
  final int tabletColumns;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = PadFormMetrics.gap;
        final int columns = constraints.maxWidth >= desktopBreakpoint
            ? desktopColumns
            : constraints.maxWidth >= tabletBreakpoint
            ? tabletColumns
            : 1;
        final double columnWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          alignment: alignment,
          spacing: gap,
          runSpacing: gap,
          children: children.map((PadFormGridItem item) {
            final int effectiveSpan = item.span > columns ? columns : item.span;
            final double itemWidth = columns == 1
                ? constraints.maxWidth
                : (columnWidth * effectiveSpan) + (gap * (effectiveSpan - 1));

            return SizedBox(width: itemWidth, child: item.child);
          }).toList(),
        );
      },
    );
  }
}
