import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RoulettePainter extends CustomPainter {
  final double animationValue;
  final List<int> numbers;
  final List<Color> colorLight;
  final List<Color> colorDark;
  final double boardFontScale;
  final double progress;

  RoulettePainter({
    required this.animationValue,
    required this.numbers,
    required this.colorLight,
    required this.colorDark,
    this.boardFontScale = 1.0,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (numbers.isEmpty) return;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = min(centerX, centerY) * 0.8;

    final Paint whitePaint = Paint()..color = Colors.white;
    final double gap = pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius + 10),
      -pi / 2 + gap / 2,
      2 * pi - gap,
      true,
      whitePaint,
    );
    final Paint whitePaintThin = Paint()..color = Colors.white24;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius + 60),
      -pi / 2,
      progress * (2 * pi),
      true,
      whitePaintThin,
    );

    double startAngle = animationValue * (pi / 180);
    final int count = numbers.length;
    final double sweepAngle = (2 * pi) / count;
    for (int i = 0; i < count; i++) {
      final Paint segmentPaint = Paint()
        ..color = colorLight[i % colorLight.length];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );
      final Paint darkPaint = Paint()..color = colorDark[i % colorDark.length];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius / 2),
        startAngle,
        sweepAngle,
        true,
        darkPaint,
      );

      if (count < 360) {
        final double textAngle = startAngle + sweepAngle / 2;
        final double textRadius = radius * 0.8;
        final double textX = centerX + textRadius * cos(textAngle);
        final double textY = centerY + textRadius * sin(textAngle);
        const double boardFontSize = 15.0;
        final tp = TextPainter(
          text: TextSpan(
              style: TextStyle(
                  color: Colors.black,
                  fontSize: boardFontSize * boardFontScale),
              text: numbers[i].toString()),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        canvas.save();
        canvas.translate(textX, textY);
        canvas.rotate(textAngle + pi / 2);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant RoulettePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        !listEquals(oldDelegate.numbers, numbers) ||
        oldDelegate.boardFontScale != boardFontScale;
  }
}
