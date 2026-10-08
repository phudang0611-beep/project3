import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedWeeklyBarChart extends StatefulWidget {
  final Map<int, double> weeklyData; // 1: Mon, ..., 7: Sun

  const AnimatedWeeklyBarChart({
    super.key,
    required this.weeklyData,
  });

  @override
  State<AnimatedWeeklyBarChart> createState() => _AnimatedWeeklyBarChartState();
}

class _AnimatedWeeklyBarChartState extends State<AnimatedWeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedWeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: WeeklyBarChartPainter(
              weeklyData: widget.weeklyData,
              animationProgress: _animation.value,
              currentWeekday: DateTime.now().weekday,
            ),
          );
        },
      ),
    );
  }
}

class WeeklyBarChartPainter extends CustomPainter {
  final Map<int, double> weeklyData;
  final double animationProgress;
  final int currentWeekday;

  WeeklyBarChartPainter({
    required this.weeklyData,
    required this.animationProgress,
    required this.currentWeekday,
  });

  static const List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 24.0;
    const topPadding = 20.0;
    final chartHeight = size.height - bottomLabelHeight - topPadding;
    final chartWidth = size.width;

    double maxVal = 0.0;
    for (int day = 1; day <= 7; day++) {
      final v = weeklyData[day] ?? 0.0;
      if (v > maxVal) maxVal = v;
    }
    // Default baseline if all 0
    if (maxVal <= 0) maxVal = 100000;

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final barWidth = (chartWidth / 7) * 0.45;
    final slotWidth = chartWidth / 7;

    for (int i = 1; i <= 7; i++) {
      final amount = weeklyData[i] ?? 0.0;
      final xCenter = slotWidth * (i - 1) + slotWidth / 2;
      final barHeight = (amount / maxVal) * chartHeight * animationProgress;

      final barLeft = xCenter - barWidth / 2;
      final barTop = topPadding + chartHeight - barHeight;
      final barRect = Rect.fromLTWH(barLeft, barTop, barWidth, barHeight);

      // Bar paint with gradient
      final isToday = (i == currentWeekday);
      final barGradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: isToday
            ? [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]
            : [const Color(0xFF818CF8), const Color(0xFFA5B4FC)],
      );

      final barPaint = Paint()
        ..shader = barGradient.createShader(barRect)
        ..style = PaintingStyle.fill;

      // Rounded bar top
      if (barHeight > 4) {
        final rRect = RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(rRect, barPaint);
      }

      // Draw value on top if amount > 0
      if (amount > 0 && animationProgress > 0.6) {
        final valText = _formatValue(amount);
        final valPainter = TextPainter(
          text: TextSpan(
            text: valText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isToday ? const Color(0xFF2563EB) : Colors.grey.shade700,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valPainter.layout();
        valPainter.paint(
          canvas,
          Offset(xCenter - valPainter.width / 2, barTop - valPainter.height - 3),
        );
      }

      // Draw day label (X axis)
      final labelPainter = TextPainter(
        text: TextSpan(
          text: dayLabels[i - 1],
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: isToday ? const Color(0xFF2563EB) : Colors.grey.shade600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          xCenter - labelPainter.width / 2,
          size.height - bottomLabelHeight + 6,
        ),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(math.min(startX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  String _formatValue(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.weeklyData != weeklyData ||
        oldDelegate.currentWeekday != currentWeekday;
  }
}

