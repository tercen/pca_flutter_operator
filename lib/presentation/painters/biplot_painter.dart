import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/pca_data.dart';

class BiplotPainter extends CustomPainter {
  final List<PcaScore> scores;
  final List<PcaLoading> loadings;
  final int pcIndexX;
  final int pcIndexY;
  final Color Function(int ci) colorForSample;
  final String Function(int ci) labelForSample;
  final double loadingThresholdPercent;
  final double loadingZoomPercent;
  final bool isDark;
  final int? hoveredIndex;
  final int? hoveredLoadingIndex;

  /// Populated during paint() for hit-testing in the view widget.
  final List<Offset> projectedScorePositions = [];
  final List<Offset> projectedArrowTips = [];
  final List<int> visibleLoadingIndices = [];

  BiplotPainter({
    required this.scores,
    required this.loadings,
    required this.pcIndexX,
    required this.pcIndexY,
    required this.colorForSample,
    required this.labelForSample,
    required this.loadingThresholdPercent,
    required this.loadingZoomPercent,
    required this.isDark,
    this.hoveredIndex,
    this.hoveredLoadingIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    projectedScorePositions.clear();
    projectedArrowTips.clear();
    visibleLoadingIndices.clear();

    if (scores.isEmpty) return;

    const padding = 60.0;
    final plotLeft = padding;
    final plotTop = padding * 0.6;
    final plotWidth = size.width - padding - plotLeft;
    final plotHeight = size.height - padding - plotTop;

    if (plotWidth <= 0 || plotHeight <= 0) return;

    final textColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final axisColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final arrowColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    // Compute score ranges
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
    if (rangeX == 0 && rangeY == 0) return;

    // Add 10% margin
    final marginX = max(rangeX * 0.1, 0.1);
    final marginY = max(rangeY * 0.1, 0.1);
    final adjMinX = minX - marginX;
    final adjMaxX = maxX + marginX;
    final adjMinY = minY - marginY;
    final adjMaxY = maxY + marginY;
    final adjRangeX = adjMaxX - adjMinX;
    final adjRangeY = adjMaxY - adjMinY;

    Offset toScreen(double dataX, double dataY) {
      final normX = (dataX - adjMinX) / adjRangeX;
      final normY = (dataY - adjMinY) / adjRangeY;
      return Offset(
          plotLeft + normX * plotWidth, plotTop + (1 - normY) * plotHeight);
    }

    // --- Bounding box ---
    final boxPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final boxRect =
        Rect.fromLTWH(plotLeft, plotTop, plotWidth, plotHeight);
    canvas.drawRect(boxRect, boxPaint);

    // --- Grid lines through origin ---
    final origin = toScreen(0, 0);
    final gridPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    // Only draw if origin is inside the plot area
    if (origin.dx > plotLeft && origin.dx < plotLeft + plotWidth) {
      canvas.drawLine(
          Offset(origin.dx, plotTop), Offset(origin.dx, plotTop + plotHeight), gridPaint);
    }
    if (origin.dy > plotTop && origin.dy < plotTop + plotHeight) {
      canvas.drawLine(
          Offset(plotLeft, origin.dy), Offset(plotLeft + plotWidth, origin.dy), gridPaint);
    }

    // --- Tick marks and labels on X axis (bottom edge) ---
    _drawLinearTicks(
      canvas: canvas,
      start: Offset(plotLeft, plotTop + plotHeight),
      end: Offset(plotLeft + plotWidth, plotTop + plotHeight),
      dataMin: adjMinX,
      dataMax: adjMaxX,
      tickDirection: const Offset(0, 1), // ticks go down
      textColor: textColor,
      tickPaint: Paint()
        ..color = axisColor
        ..strokeWidth = 1.0,
    );

    // --- Tick marks and labels on Y axis (left edge) ---
    _drawLinearTicks(
      canvas: canvas,
      start: Offset(plotLeft, plotTop + plotHeight),
      end: Offset(plotLeft, plotTop),
      dataMin: adjMinY,
      dataMax: adjMaxY,
      tickDirection: const Offset(-1, 0), // ticks go left
      textColor: textColor,
      tickPaint: Paint()
        ..color = axisColor
        ..strokeWidth = 1.0,
      alignRight: true,
    );

    // --- Axis labels ---
    final xLabel = TextPainter(
      text: TextSpan(
          text: 'PC${pcIndexX + 1}',
          style: TextStyle(
              color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabel.paint(
        canvas,
        Offset(plotLeft + plotWidth / 2 - xLabel.width / 2,
            plotTop + plotHeight + 35));

    canvas.save();
    canvas.translate(15, plotTop + plotHeight / 2);
    canvas.rotate(-pi / 2);
    final yLabel = TextPainter(
      text: TextSpan(
          text: 'PC${pcIndexY + 1}',
          style: TextStyle(
              color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    yLabel.paint(canvas, Offset(-yLabel.width / 2, 0));
    canvas.restore();

    // --- Loading arrows (labels shown only on hover) ---
    if (loadingThresholdPercent > 0) {
      final magnitudes = loadings.map((l) {
        final lx = l[pcIndexX];
        final ly = l[pcIndexY];
        return sqrt(lx * lx + ly * ly);
      }).toList();

      final sortedMags = List<double>.from(magnitudes)..sort();
      final cutoffIndex =
          ((1 - loadingThresholdPercent / 100) * sortedMags.length)
              .floor()
              .clamp(0, sortedMags.length - 1);
      final cutoff = sortedMags[cutoffIndex];

      final zoomFactor = loadingZoomPercent / 100.0;
      final loadingScale = max(adjRangeX, adjRangeY) * 0.4 * zoomFactor;

      final arrowPaint = Paint()
        ..color = arrowColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      for (var i = 0; i < loadings.length; i++) {
        if (magnitudes[i] < cutoff) continue;

        final l = loadings[i];
        final lx = l[pcIndexX] * loadingScale;
        final ly = l[pcIndexY] * loadingScale;

        final tipScreen = toScreen(lx, ly);
        final originScreen = origin;

        visibleLoadingIndices.add(i);
        projectedArrowTips.add(tipScreen);

        final isHoveredLoading = hoveredLoadingIndex == i;
        final currentArrowPaint = isHoveredLoading
            ? (Paint()
              ..color = textColor
              ..strokeWidth = 2.0
              ..style = PaintingStyle.stroke)
            : arrowPaint;

        // Draw arrow line
        canvas.drawLine(originScreen, tipScreen, currentArrowPaint);

        // Draw arrowhead
        final angle = atan2(
            tipScreen.dy - originScreen.dy, tipScreen.dx - originScreen.dx);
        const headLen = 8.0;
        const headAngle = 0.4;
        final p1 = Offset(
          tipScreen.dx - headLen * cos(angle - headAngle),
          tipScreen.dy - headLen * sin(angle - headAngle),
        );
        final p2 = Offset(
          tipScreen.dx - headLen * cos(angle + headAngle),
          tipScreen.dy - headLen * sin(angle + headAngle),
        );
        canvas.drawLine(tipScreen, p1, currentArrowPaint);
        canvas.drawLine(tipScreen, p2, currentArrowPaint);

        // Show variable name only on hover
        if (isHoveredLoading) {
          final nameTp = TextPainter(
            text: TextSpan(
              text: l.variable,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          // Background for readability
          final labelRect = Rect.fromLTWH(
            tipScreen.dx + 6,
            tipScreen.dy - nameTp.height / 2 - 2,
            nameTp.width + 6,
            nameTp.height + 4,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
            Paint()
              ..color = (isDark ? const Color(0xFF1F2937) : Colors.white)
                  .withValues(alpha: 0.9),
          );
          nameTp.paint(canvas,
              Offset(tipScreen.dx + 9, tipScreen.dy - nameTp.height / 2));
        }
      }
    }

    // --- Score points ---
    for (final s in scores) {
      final pos = toScreen(s[pcIndexX], s[pcIndexY]);
      projectedScorePositions.add(pos);

      final label = labelForSample(s.ci);
      final color = colorForSample(s.ci);
      final isHovered = hoveredIndex == s.ci;

      if (isHovered) {
        canvas.drawCircle(
            pos, 8, Paint()..color = color.withValues(alpha: 0.3));
      }

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: isHovered ? 12 : 11,
            fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  void _drawLinearTicks({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required double dataMin,
    required double dataMax,
    required Offset tickDirection,
    required Color textColor,
    required Paint tickPaint,
    bool alignRight = false,
  }) {
    const numTicks = 5;
    const tickLen = 4.0;

    for (var i = 0; i <= numTicks; i++) {
      final t = i / numTicks;
      final pos = Offset(
        start.dx + (end.dx - start.dx) * t,
        start.dy + (end.dy - start.dy) * t,
      );
      final tickEnd = Offset(
        pos.dx + tickDirection.dx * tickLen,
        pos.dy + tickDirection.dy * tickLen,
      );

      canvas.drawLine(pos, tickEnd, tickPaint);

      final value = dataMin + (dataMax - dataMin) * t;
      final valueStr = value.abs() < 1
          ? value.toStringAsFixed(2)
          : value.toStringAsFixed(1);

      final tp = TextPainter(
        text: TextSpan(
          text: valueStr,
          style: TextStyle(
              color: textColor.withValues(alpha: 0.7), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      if (alignRight) {
        tp.paint(canvas,
            Offset(tickEnd.dx - tp.width - 3, tickEnd.dy - tp.height / 2));
      } else {
        tp.paint(
            canvas, Offset(tickEnd.dx - tp.width / 2, tickEnd.dy + 2));
      }
    }
  }

  @override
  bool shouldRepaint(BiplotPainter oldDelegate) => true;
}
