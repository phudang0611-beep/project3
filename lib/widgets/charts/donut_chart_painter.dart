import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/category_model.dart';

class DonutChartData {
  final ExpenseCategory category;
  final double amount;
  final double percentage;

  DonutChartData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class AnimatedDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> data;
  final double totalAmount;

  const AnimatedDonutChart({
    super.key,
    required this.data,
    required this.totalAmount,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount) {
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
    final validEntries = widget.data.entries
        .where((e) => e.value > 0)
        .toList();

    if (widget.totalAmount <= 0 || validEntries.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No expense data yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final chartItems = validEntries.map((e) {
      return DonutChartData(
        category: e.key,
        amount: e.value,
        percentage: (e.value / widget.totalAmount) * 100,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          width: 220,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: DonutChartPainter(
                  items: chartItems,
                  animationProgress: _animation.value,
                  totalAmount: widget.totalAmount,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Custom Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: chartItems.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.category.displayName}: ${item.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<DonutChartData> items;
  final double animationProgress;
  final double totalAmount;

  DonutChartPainter({
    required this.items,
    required this.animationProgress,
    required this.totalAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 34.0;
    final arcRadius = radius - strokeWidth / 2;

    // Draw background track
    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, arcRadius, trackPaint);

    if (items.isEmpty) return;

    // Starting from top (-pi / 2)
    double startAngle = -math.pi / 2;
    final totalSweepTarget = 2 * math.pi * animationProgress;

    for (final item in items) {
      final sweepAngle = (item.amount / totalAmount) * totalSweepTarget;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = item.category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Small gap between slices
      final adjustedSweep = math.max(0.01, sweepAngle - 0.04);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle + 0.02,
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Center text: Total summary
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Total\n',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: _formatCurrency(totalAmount * animationProgress),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  String _formatCurrency(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.items != items;
  }
}

