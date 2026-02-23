import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/pca_data.dart';

class PairsCellPainter extends CustomPainter {
  final List<PcaScore> scores;
  final int pcIndexX;
  final int pcIndexY;
  final Color Function(int ci) colorForSample;
  final bool showXTicks;
  final bool showYTicks;
  final Color tickColor;

  PairsCellPainter({
    required this.scores,
    required this.pcIndexX,
    required this.pcIndexY,
    required this.colorForSample,
    this.showXTicks = false,
    this.showYTicks = false,
    this.tickColor = const Color(0xFF9CA3AF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    const padding = 6.0;
    final plotLeft = padding;
    final plotTop = padding;
    final plotWidth = size.width - padding * 2;
    final plotHeight = size.height - padding * 2;

    if (plotWidth <= 0 || plotHeight <= 0) return;

    // Compute ranges
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final s in scores) {
      final x = s[pcIndexX];
      final y = s[pcIndexY];
      minX = min(minX, x);
      maxX = max(maxX, x);
      minY = min(minY, y);
      maxY = max(maxY, y);
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    if (rangeX == 0 || rangeY == 0) return;

    // Add 5% margin
    final marginX = rangeX * 0.05;
    final marginY = rangeY * 0.05;
    final adjMinX = minX - marginX;
    final adjMaxX = maxX + marginX;
    final adjMinY = minY - marginY;
    final adjMaxY = maxY + marginY;
    final adjRangeX = adjMaxX - adjMinX;
    final adjRangeY = adjMaxY - adjMinY;

    // Draw data points
    for (final s in scores) {
      final normX = (s[pcIndexX] - adjMinX) / adjRangeX;
      final normY = (s[pcIndexY] - adjMinY) / adjRangeY;
      final px = plotLeft + normX * plotWidth;
      final py = plotTop + (1 - normY) * plotHeight;

      canvas.drawCircle(
        Offset(px, py),
        3,
        Paint()..color = colorForSample(s.ci),
      );
    }

    // Tick marks on outer edges — 5 ticks, inward-pointing
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.0;

    const numTicks = 4;
    const tickLen = 4.0;

    if (showYTicks) {
      // Horizontal ticks on the left edge, pointing right
      for (var i = 0; i <= numTicks; i++) {
        final t = i / numTicks;
        final y = plotTop + (1 - t) * plotHeight;
        canvas.drawLine(
          Offset(plotLeft, y),
          Offset(plotLeft + tickLen, y),
          tickPaint,
        );
      }
    }

    if (showXTicks) {
      // Vertical ticks on the bottom edge, pointing up
      for (var i = 0; i <= numTicks; i++) {
        final t = i / numTicks;
        final x = plotLeft + t * plotWidth;
        canvas.drawLine(
          Offset(x, plotTop + plotHeight),
          Offset(x, plotTop + plotHeight - tickLen),
          tickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PairsCellPainter oldDelegate) => true;
}
