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

    const leftMargin = 60.0;
    const rightMargin = 20.0;
    const topMargin = 36.0;
    const bottomMargin = 40.0;

    final chartLeft = leftMargin;
    final chartRight = size.width - rightMargin;
    final chartTop = topMargin;
    final chartBottom = size.height - bottomMargin;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Use raw eigenvalues (matching R's screeplot)
    final maxValue = variance.map((v) => v.variance).reduce(max);
    // Round up to a nice number for the Y-axis
    final maxY = _niceMax(maxValue);

    final textColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final gridColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    // Light blue fill + thin border (matching R's screeplot)
    final barFillColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFFADD8E6);
    final barBorderColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF000000);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Title
    final titleTp = TextPainter(
      text: TextSpan(
        text: 'variance explained per component',
        style: TextStyle(color: textColor, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(
      canvas,
      Offset((size.width - titleTp.width) / 2, 8),
    );

    // Draw axes
    canvas.drawLine(Offset(chartLeft, chartTop), Offset(chartLeft, chartBottom), axisPaint);
    canvas.drawLine(Offset(chartLeft, chartBottom), Offset(chartRight, chartBottom), axisPaint);

    // Y-axis grid lines and labels (raw variance values)
    const numGridLines = 5;
    for (var i = 0; i <= numGridLines; i++) {
      final value = maxY * i / numGridLines;
      final y = chartBottom - (value / maxY) * chartHeight;

      if (i > 0) {
        canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: _formatAxisValue(value),
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
        text: 'Variances',
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

    final fillPaint = Paint()..color = barFillColor;
    final borderPaint = Paint()
      ..color = barBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var i = 0; i < barCount; i++) {
      final v = variance[i];
      final barHeight = (v.variance / maxY) * chartHeight;
      final x = chartLeft + gap + i * (barWidth + gap);
      final y = chartBottom - barHeight;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);

      // X-axis label (skip some if too many bars)
      if (barCount <= 15 || i % 2 == 0) {
        final xTp = TextPainter(
          text: TextSpan(
            text: v.label,
            style: TextStyle(color: textColor, fontSize: barCount > 15 ? 8 : 11),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        xTp.paint(canvas, Offset(x + barWidth / 2 - xTp.width / 2, chartBottom + 6));
      }
    }
  }

  /// Round up to a "nice" axis maximum (e.g. 50, 100, 200, 500, 1000...)
  double _niceMax(double value) {
    if (value <= 0) return 1;
    final magnitude = pow(10, (log(value) / ln10).floor()).toDouble();
    final normalized = value / magnitude;
    if (normalized <= 1) return magnitude;
    if (normalized <= 2) return 2 * magnitude;
    if (normalized <= 5) return 5 * magnitude;
    return 10 * magnitude;
  }

  /// Format axis values: use integers for large values, decimals for small
  String _formatAxisValue(double value) {
    if (value >= 10) return value.toStringAsFixed(0);
    if (value >= 1) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }

  @override
  bool shouldRepaint(VariationPainter oldDelegate) =>
      oldDelegate.variance != variance || oldDelegate.isDark != isDark;
}
