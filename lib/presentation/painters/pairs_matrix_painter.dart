import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/pca_data.dart';

class PairsCellPainter extends CustomPainter {
  final List<PcaScore> scores;
  final int pcIndexX;
  final int pcIndexY;
  final Color Function(int ci) colorForSample;

  PairsCellPainter({
    required this.scores,
    required this.pcIndexX,
    required this.pcIndexY,
    required this.colorForSample,
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
  }

  @override
  bool shouldRepaint(PairsCellPainter oldDelegate) => true;
}
