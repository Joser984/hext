import 'package:flutter/material.dart';

enum AppChipTone { neutral, info, success, warning, danger, accent }

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.tone = AppChipTone.neutral,
    this.leadingDot = false,
  });

  final String label;
  final AppChipTone tone;
  final bool leadingDot;

  @override
  Widget build(BuildContext context) {
    final _AppChipPalette palette = _paletteFor(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leadingDot) ...<Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: palette.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: palette.foreground,
            ),
          ),
        ],
      ),
    );
  }

  _AppChipPalette _paletteFor(AppChipTone tone) {
    switch (tone) {
      case AppChipTone.info:
        return const _AppChipPalette(
          background: Color(0xFFEFF6FF),
          border: Color(0xFFD7E7FF),
          foreground: Color(0xFF215A99),
        );
      case AppChipTone.success:
        return const _AppChipPalette(
          background: Color(0xFFEFFAF4),
          border: Color(0xFFD6EEDC),
          foreground: Color(0xFF17726D),
        );
      case AppChipTone.warning:
        return const _AppChipPalette(
          background: Color(0xFFFFF7EA),
          border: Color(0xFFF4DFC0),
          foreground: Color(0xFF9A6700),
        );
      case AppChipTone.danger:
        return const _AppChipPalette(
          background: Color(0xFFFEF1F1),
          border: Color(0xFFF3CDCD),
          foreground: Color(0xFFB42318),
        );
      case AppChipTone.accent:
        return const _AppChipPalette(
          background: Color(0xFFF3EEFF),
          border: Color(0xFFE0D4FF),
          foreground: Color(0xFF6E3CBC),
        );
      case AppChipTone.neutral:
        return const _AppChipPalette(
          background: Color(0xFFF5F7FA),
          border: Color(0xFFE1E6ED),
          foreground: Color(0xFF5F6B7A),
        );
    }
  }
}

class _AppChipPalette {
  const _AppChipPalette({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
