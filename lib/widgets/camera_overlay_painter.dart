import 'package:flutter/material.dart';

class CameraOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double scanLineProgress; // 0.0 to 1.0

  CameraOverlayPainter({
    required this.scanWindow,
    this.scanLineProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark semi-transparent backdrop
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // Use path with PathFillType.evenOdd to punch a hole for the viewfinder
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(bgPath, backgroundPaint);

    // 2. Window border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      borderPaint,
    );

    // 3. Four corner guide brackets
    final cornerPaint = Paint()
      ..color = const Color(0xFF38BDF8) // Bright Cyan accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    const r = 16.0;

    // Top-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.left, scanWindow.top + cornerLen)
        ..lineTo(scanWindow.left, scanWindow.top + r)
        ..quadraticBezierTo(scanWindow.left, scanWindow.top, scanWindow.left + r, scanWindow.top)
        ..lineTo(scanWindow.left + cornerLen, scanWindow.top),
      cornerPaint,
    );

    // Top-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.right - cornerLen, scanWindow.top)
        ..lineTo(scanWindow.right - r, scanWindow.top)
        ..quadraticBezierTo(scanWindow.right, scanWindow.top, scanWindow.right, scanWindow.top + r)
        ..lineTo(scanWindow.right, scanWindow.top + cornerLen),
      cornerPaint,
    );

    // Bottom-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.left, scanWindow.bottom - cornerLen)
        ..lineTo(scanWindow.left, scanWindow.bottom - r)
        ..quadraticBezierTo(scanWindow.left, scanWindow.bottom, scanWindow.left + r, scanWindow.bottom)
        ..lineTo(scanWindow.left + cornerLen, scanWindow.bottom),
      cornerPaint,
    );

    // Bottom-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.right - cornerLen, scanWindow.bottom)
        ..lineTo(scanWindow.right - r, scanWindow.bottom)
        ..quadraticBezierTo(scanWindow.right, scanWindow.bottom, scanWindow.right, scanWindow.bottom - r)
        ..lineTo(scanWindow.right, scanWindow.bottom - cornerLen),
      cornerPaint,
    );

    // 4. Animated scan line
    if (scanLineProgress > 0) {
      final lineY = scanWindow.top + (scanWindow.height * scanLineProgress);
      final scanLinePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.cyan.withValues(alpha: 0.0),
            Colors.cyanAccent.withValues(alpha: 0.8),
            Colors.cyan.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(scanWindow.left, lineY, scanWindow.width, 2))
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(scanWindow.left + 8, lineY),
        Offset(scanWindow.right - 8, lineY),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow ||
        oldDelegate.scanLineProgress != scanLineProgress;
  }
}

