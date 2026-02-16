import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/pca_data.dart';

class VariationPainter extends CustomPainter {
  final List<PcVariance> variance;
  final bool isDark;

  VariationPainter({required this.variance, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (variance.isEmpty) return;

    const leftMargin = 50.0;
    const rightMargin = 20.0;
    const topMargin = 20.0;
    const bottomMargin = 40.0;

    final chartLeft = leftMargin;
    final chartRight = size.width - rightMargin;
    final chartTop = topMargin;
    final chartBottom = size.height - bottomMargin;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final maxPercent = (variance.map((v) => v.percent).reduce(max) * 1.15).ceilToDouble();

    final textColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final gridColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final barColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Draw axes
    canvas.drawLine(Offset(chartLeft, chartTop), Offset(chartLeft, chartBottom), axisPaint);
    canvas.drawLine(Offset(chartLeft, chartBottom), Offset(chartRight, chartBottom), axisPaint);

    // Y-axis grid lines and labels
    final numGridLines = 5;
    for (var i = 0; i <= numGridLines; i++) {
      final pct = maxPercent * i / numGridLines;
      final y = chartBottom - (pct / maxPercent) * chartHeight;

      if (i > 0) {
        canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '${pct.toStringAsFixed(0)}%',
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartLeft - tp.width - 6, y - tp.height / 2));
    }

    // Y-axis label
    canvas.save();
    canvas.translate(12, chartTop + chartHeight / 2);
    canvas.rotate(-pi / 2);
    final yLabel = TextPainter(
      text: TextSpan(
        text: 'Variance Explained (%)',
        style: TextStyle(color: textColor, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yLabel.paint(canvas, Offset(-yLabel.width / 2, 0));
    canvas.restore();

    // Draw bars
    final barCount = variance.length;
    final gap = chartWidth * 0.15 / (barCount + 1);
    final barWidth = (chartWidth - gap * (barCount + 1)) / barCount;

    final barPaint = Paint()..color = barColor;

    for (var i = 0; i < barCount; i++) {
      final v = variance[i];
      final barHeight = (v.percent / maxPercent) * chartHeight;
      final x = chartLeft + gap + i * (barWidth + gap);
      final y = chartBottom - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);

      // Percentage label above bar
      final pctTp = TextPainter(
        text: TextSpan(
          text: '${v.percent.toStringAsFixed(1)}%',
          style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      pctTp.paint(canvas, Offset(x + barWidth / 2 - pctTp.width / 2, y - pctTp.height - 4));

      // X-axis label
      final xTp = TextPainter(
        text: TextSpan(
          text: v.label,
          style: TextStyle(color: textColor, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      xTp.paint(canvas, Offset(x + barWidth / 2 - xTp.width / 2, chartBottom + 6));
    }
  }

  @override
  bool shouldRepaint(VariationPainter oldDelegate) =>
      oldDelegate.variance != variance || oldDelegate.isDark != isDark;
}
