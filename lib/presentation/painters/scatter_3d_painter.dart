import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/pca_data.dart';

class Scatter3dPainter extends CustomPainter {
  final List<PcaScore> scores;
  final int pcIndexX;
  final int pcIndexY;
  final int pcIndexZ;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final Color Function(int ci) colorForSample;
  final String Function(int ci) labelForSample;
  final PointStyle pointStyle;
  final bool isDark;
  final int? hoveredIndex;

  /// Populated during paint() for hit-testing.
  final List<Offset> projectedPositions = [];

  Scatter3dPainter({
    required this.scores,
    required this.pcIndexX,
    required this.pcIndexY,
    required this.pcIndexZ,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.colorForSample,
    required this.labelForSample,
    required this.pointStyle,
    required this.isDark,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    projectedPositions.clear();

    if (scores.isEmpty) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    // Base scale fills ~80% of the smaller dimension at zoom=1.0.
    // The cube diagonal in projected space is roughly sqrt(3)*2 ≈ 3.46 units,
    // so 0.42 * minDim gives good fill.
    final scale = min(size.width, size.height) * 0.42 * zoom;

    final textColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final axisColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    // Compute data ranges for each axis
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    double minZ = double.infinity, maxZ = double.negativeInfinity;

    for (final s in scores) {
      minX = min(minX, s[pcIndexX]);
      maxX = max(maxX, s[pcIndexX]);
      minY = min(minY, s[pcIndexY]);
      maxY = max(maxY, s[pcIndexY]);
      minZ = min(minZ, s[pcIndexZ]);
      maxZ = max(maxZ, s[pcIndexZ]);
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final rangeZ = maxZ - minZ;
    if (rangeX == 0 && rangeY == 0 && rangeZ == 0) return;

    final midX = (minX + maxX) / 2;
    final midY = (minY + maxY) / 2;
    final midZ = (minZ + maxZ) / 2;

    // Per-axis normalization to -1..1 — this makes a cube, not a rectangle.
    // Each axis is independently scaled so all three span the same visual length.
    final safeRangeX = rangeX == 0 ? 1.0 : rangeX;
    final safeRangeY = rangeY == 0 ? 1.0 : rangeY;
    final safeRangeZ = rangeZ == 0 ? 1.0 : rangeZ;

    List<double> normalize(double x, double y, double z) => [
          (x - midX) / safeRangeX * 2,
          (y - midY) / safeRangeY * 2,
          (z - midZ) / safeRangeZ * 2,
        ];

    // Rotation matrices
    final cosRx = cos(rotationX), sinRx = sin(rotationX);
    final cosRy = cos(rotationY), sinRy = sin(rotationY);

    List<double> rotate(double x, double y, double z) {
      final x1 = cosRy * x + sinRy * z;
      final z1 = -sinRy * x + cosRy * z;
      final y1 = cosRx * y - sinRx * z1;
      final z2 = sinRx * y + cosRx * z1;
      return [x1, y1, z2];
    }

    Offset project(List<double> p) {
      const focalLength = 4.0;
      final perspScale = focalLength / (focalLength + p[2] + 2);
      return Offset(
          cx + p[0] * scale * perspScale, cy - p[1] * scale * perspScale);
    }

    // --- Wireframe bounding cube ---
    // All extents are 1.0 now (cube), since we normalize per-axis
    const ext = 1.0;

    final corners = <List<double>>[
      [-ext, -ext, -ext], // 0: left-bottom-back
      [ext, -ext, -ext], // 1: right-bottom-back
      [ext, ext, -ext], // 2: right-top-back
      [-ext, ext, -ext], // 3: left-top-back
      [-ext, -ext, ext], // 4: left-bottom-front
      [ext, -ext, ext], // 5: right-bottom-front
      [ext, ext, ext], // 6: right-top-front
      [-ext, ext, ext], // 7: left-top-front
    ];

    const edges = [
      [0, 1], [1, 2], [2, 3], [3, 0], // back face
      [4, 5], [5, 6], [6, 7], [7, 4], // front face
      [0, 4], [1, 5], [2, 6], [3, 7], // connecting edges
    ];

    final cubePaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final projectedCorners = corners.map((c) {
      final r = rotate(c[0], c[1], c[2]);
      return project(r);
    }).toList();

    for (final edge in edges) {
      canvas.drawLine(
          projectedCorners[edge[0]], projectedCorners[edge[1]], cubePaint);
    }

    // --- Tick marks & labels on 3 edges ---
    _drawAxisTicks(
      canvas: canvas,
      rotate: rotate,
      project: project,
      corner0: corners[0],
      corner1: corners[1],
      dataMin: minX,
      dataMax: maxX,
      label: 'PC${pcIndexX + 1}',
      textColor: textColor,
      tickDir: [0, -1, 0],
    );
    _drawAxisTicks(
      canvas: canvas,
      rotate: rotate,
      project: project,
      corner0: corners[0],
      corner1: corners[3],
      dataMin: minY,
      dataMax: maxY,
      label: 'PC${pcIndexY + 1}',
      textColor: textColor,
      tickDir: [-1, 0, 0],
    );
    _drawAxisTicks(
      canvas: canvas,
      rotate: rotate,
      project: project,
      corner0: corners[0],
      corner1: corners[4],
      dataMin: minZ,
      dataMax: maxZ,
      label: 'PC${pcIndexZ + 1}',
      textColor: textColor,
      tickDir: [0, -1, 0],
    );

    // --- Data points ---
    final indexed = <_IndexedPoint>[];
    for (var i = 0; i < scores.length; i++) {
      final s = scores[i];
      final norm = normalize(s[pcIndexX], s[pcIndexY], s[pcIndexZ]);
      final rot = rotate(norm[0], norm[1], norm[2]);
      final screen = project(rot);
      indexed.add(_IndexedPoint(i, s.ci, rot[2], screen));
    }
    indexed.sort((a, b) => a.z.compareTo(b.z));

    projectedPositions.addAll(List.filled(scores.length, Offset.zero));
    for (final ip in indexed) {
      projectedPositions[ip.index] = ip.screen;
    }

    for (final ip in indexed) {
      final color = colorForSample(ip.ci);
      final isHovered = hoveredIndex == ip.ci;

      const focalLength = 4.0;
      final depthFactor = focalLength / (focalLength + ip.z + 2);

      if (pointStyle == PointStyle.spheres) {
        final radius = (8.0 * depthFactor).clamp(3.0, 14.0);
        if (isHovered) {
          canvas.drawCircle(
              ip.screen, radius + 5, Paint()..color = color.withValues(alpha: 0.3));
        }
        canvas.drawCircle(ip.screen, radius, Paint()..color = color);
        canvas.drawCircle(
          Offset(ip.screen.dx - radius * 0.25, ip.screen.dy - radius * 0.25),
          radius * 0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.4),
        );
      } else {
        final label = labelForSample(ip.ci);
        final fontSize = isHovered ? 14.0 : 12.0;
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        if (isHovered) {
          canvas.drawCircle(
              ip.screen, 12, Paint()..color = color.withValues(alpha: 0.2));
        }
        tp.paint(canvas,
            Offset(ip.screen.dx - tp.width / 2, ip.screen.dy - tp.height / 2));
      }
    }
  }

  void _drawAxisTicks({
    required Canvas canvas,
    required List<double> Function(double, double, double) rotate,
    required Offset Function(List<double>) project,
    required List<double> corner0,
    required List<double> corner1,
    required double dataMin,
    required double dataMax,
    required String label,
    required Color textColor,
    required List<double> tickDir,
  }) {
    const numTicks = 5;
    const tickLength = 0.03; // Short ticks — just visual markers
    const labelGap = 0.08; // Gap between edge and label center

    final tickPaint = Paint()
      ..color = textColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;

    for (var i = 0; i <= numTicks; i++) {
      final t = i / numTicks;
      final pos = [
        corner0[0] + (corner1[0] - corner0[0]) * t,
        corner0[1] + (corner1[1] - corner0[1]) * t,
        corner0[2] + (corner1[2] - corner0[2]) * t,
      ];
      final tickEnd = [
        pos[0] + tickDir[0] * tickLength,
        pos[1] + tickDir[1] * tickLength,
        pos[2] + tickDir[2] * tickLength,
      ];

      final posR = rotate(pos[0], pos[1], pos[2]);
      final tickR = rotate(tickEnd[0], tickEnd[1], tickEnd[2]);
      final posP = project(posR);
      final tickP = project(tickR);

      canvas.drawLine(posP, tickP, tickPaint);

      // Label positioned past the tick with a clear gap
      final labelPos = [
        pos[0] + tickDir[0] * labelGap,
        pos[1] + tickDir[1] * labelGap,
        pos[2] + tickDir[2] * labelGap,
      ];
      final labelR = rotate(labelPos[0], labelPos[1], labelPos[2]);
      final labelP = project(labelR);

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

      tp.paint(
          canvas, Offset(labelP.dx - tp.width / 2, labelP.dy - tp.height / 2));
    }

    // Axis name label further out from midpoint
    final mid = [
      (corner0[0] + corner1[0]) / 2 + tickDir[0] * labelGap * 2.5,
      (corner0[1] + corner1[1]) / 2 + tickDir[1] * labelGap * 2.5,
      (corner0[2] + corner1[2]) / 2 + tickDir[2] * labelGap * 2.5,
    ];
    final midR = rotate(mid[0], mid[1], mid[2]);
    final midP = project(midR);

    final axisLabel = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    axisLabel.paint(canvas,
        Offset(midP.dx - axisLabel.width / 2, midP.dy - axisLabel.height / 2));
  }

  @override
  bool shouldRepaint(Scatter3dPainter oldDelegate) => true;
}

class _IndexedPoint {
  final int index;
  final int ci;
  final double z;
  final Offset screen;

  _IndexedPoint(this.index, this.ci, this.z, this.screen);
}
