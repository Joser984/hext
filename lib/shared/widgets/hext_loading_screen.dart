import 'package:flutter/material.dart';
import 'package:hext/shared/widgets/hext_animated_logo.dart';
import 'package:hext/shared/widgets/hext_mark.dart';

class HextLoadingScreen extends StatelessWidget {
  const HextLoadingScreen({
    super.key,
    this.title = 'Cargando HEXT',
    this.subtitle = 'Preparando entorno institucional',
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        compact
            ? HextMark(
                size: 72,
                variant: HextMarkVariant.transparentMark,
                color: const Color(0xFF17726D),
              )
            : const HextAnimatedLogo(size: 110),
        SizedBox(height: compact ? 18 : 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 18 : 24,
            fontWeight: FontWeight.w700,
            color: compact ? const Color(0xFF17726D) : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 13 : 14,
            color: compact ? const Color(0xFF5B6474) : const Color(0xCCEAF3F2),
          ),
        ),
        SizedBox(height: compact ? 18 : 24),
        SizedBox(
          width: compact ? 22 : 26,
          height: compact ? 22 : 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: compact ? const Color(0xFF17726D) : Colors.white,
          ),
        ),
      ],
    );

    if (compact) {
      return Center(child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF17726D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }
}
