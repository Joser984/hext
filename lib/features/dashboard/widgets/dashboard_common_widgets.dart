import 'package:flutter/material.dart';
import 'package:hext/shared/widgets/hext_card.dart';

// Constantes visuales locales para widgets extraídos
const dashboardCardBg = Colors.white;
const dashboardBorderColor = Color(0xFFE2E6EA);
const dashboardTitleColor = Color(0xFF1F2937);
const dashboardTextColor = Color(0xFF4B5563);
const dashboardMutedColor = Color(0xFF6B7280);
const dashboardPrimary = Color(0xFF17726D);

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HextCard(
      padding: padding,
      child: child,
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: dashboardTitleColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13.5,
                color: dashboardMutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const LegendDot({
    required this.label,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 14, color: dashboardTextColor),
      ),
    ],
  );
}

class Bar extends StatelessWidget {
  final int value;
  final int max;
  final Color color;
  final bool compact;
  final double maxPixels;
  final bool showValue;
  final Color? valueColor;
  final String? semanticLabel;

  const Bar({
    required this.value,
    required this.max,
    required this.color,
    this.compact = false,
    this.maxPixels = 150,
    this.showValue = false,
    this.valueColor,
    this.semanticLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double height = max == 0 ? 0 : (value / max) * maxPixels;
    final bool placeValueAbove = !compact || height >= 22;
    final Widget valueText = Text(
      '$value',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: valueColor ?? dashboardMutedColor,
      ),
    );
    final Widget barShape = Container(
      width: compact ? 14 : 20,
      height: height.clamp(compact ? 4 : 8, maxPixels),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Tooltip(
      message: semanticLabel == null ? '$value' : '$semanticLabel: $value',
      waitDuration: const Duration(milliseconds: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (!compact || (showValue && placeValueAbove)) valueText,
          SizedBox(
            height: !compact || (showValue && placeValueAbove)
                ? (compact ? 4 : 8)
                : 0,
          ),
          if (compact && showValue && !placeValueAbove) ...<Widget>[
            valueText,
            const SizedBox(height: 2),
          ],
          barShape,
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;

  const StatusPill({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final String normalized = label.toLowerCase();

    Color bg = const Color(0xFFFFF8ED);
    Color border = const Color(0xFFF4DFC0);
    Color text = const Color(0xFF9A6700);

    if (normalized == 'realizada' || normalized == 'en curso') {
      bg = const Color(0xFFF1F8F6);
      border = const Color(0xFFD9ECE7);
      text = const Color(0xFF17726D);
    } else if (normalized == 'retrasada') {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFF6D1D1);
      text = const Color(0xFFB42318);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

class MapLocationLink extends StatelessWidget {
  const MapLocationLink({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.place_outlined,
              size: 16,
              color: dashboardPrimary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dashboardPrimary,
                  decoration: TextDecoration.underline,
                  decorationColor: dashboardPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
