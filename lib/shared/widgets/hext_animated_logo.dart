import 'package:flutter/material.dart';

class HextAnimatedLogo extends StatefulWidget {
  const HextAnimatedLogo({super.key, this.size = 96});

  final double size;

  @override
  State<HextAnimatedLogo> createState() => _HextAnimatedLogoState();
}

class _HextAnimatedLogoState extends State<HextAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _draw;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _draw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.68, curve: Curves.easeInOutCubic),
    );

    _pulse = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 68),
      TweenSequenceItem(tween: Tween(begin: 1.00, end: 1.08), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.98), weight: 7),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.04), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.00), weight: 11),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => Transform.scale(
          scale: _pulse.value,
          child: CustomPaint(
            painter: _HextLogoPainter(_draw.value),
          ),
        ),
      ),
    );
  }
}

class _HextLogoPainter extends CustomPainter {
  const _HextLogoPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 100;

    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final List<Path> segments = <Path>[
      Path()
        ..moveTo(50 * s, 58 * s)
        ..lineTo(50 * s, 18 * s),
      Path()
        ..moveTo(50 * s, 18 * s)
        ..lineTo(76 * s, 34 * s),
      Path()
        ..moveTo(76 * s, 34 * s)
        ..lineTo(76 * s, 88 * s),
      Path()
        ..moveTo(76 * s, 88 * s)
        ..lineTo(50 * s, 88 * s),
      Path()
        ..moveTo(50 * s, 88 * s)
        ..lineTo(50 * s, 58 * s),
      Path()
        ..moveTo(50 * s, 58 * s)
        ..lineTo(24 * s, 34 * s),
      Path()
        ..moveTo(24 * s, 34 * s)
        ..lineTo(24 * s, 88 * s),
      Path()
        ..moveTo(24 * s, 88 * s)
        ..lineTo(50 * s, 88 * s),
      Path()
        ..moveTo(42 * s, 40 * s)
        ..lineTo(42 * s, 58 * s),
      Path()
        ..moveTo(42 * s, 72 * s)
        ..lineTo(42 * s, 84 * s),
    ];

    _drawSegments(canvas, segments, paint, progress);
  }

  void _drawSegments(
    Canvas canvas,
    List<Path> segments,
    Paint paint,
    double progress,
  ) {
    final double total = segments.fold<double>(0, (double sum, Path path) {
      return sum + path.computeMetrics().first.length;
    });

    double remaining = total * progress;

    for (final Path path in segments) {
      final dynamic metric = path.computeMetrics().first;
      final double length = metric.length as double;
      final double visible = remaining.clamp(0.0, length).toDouble();

      if (visible > 0) {
        canvas.drawPath(metric.extractPath(0, visible), paint);
      }

      remaining -= length;
      if (remaining <= 0) break;
    }
  }

  @override
  bool shouldRepaint(covariant _HextLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
