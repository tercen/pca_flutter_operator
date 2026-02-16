import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../domain/models/pca_data.dart';
import '../../painters/scatter_3d_painter.dart';
import '../../providers/app_state_provider.dart';

class Scores3dView extends StatefulWidget {
  final PcaData data;
  final AppStateProvider provider;
  final bool isDark;

  const Scores3dView({
    super.key,
    required this.data,
    required this.provider,
    required this.isDark,
  });

  @override
  State<Scores3dView> createState() => _Scores3dViewState();
}

class _Scores3dViewState extends State<Scores3dView> {
  Scatter3dPainter? _painter;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    _painter = Scatter3dPainter(
      scores: widget.data.scores,
      pcIndexX: provider.pcIndex(provider.scores3dXAxis),
      pcIndexY: provider.pcIndex(provider.scores3dYAxis),
      pcIndexZ: provider.pcIndex(provider.scores3dZAxis),
      rotationX: provider.rotationX,
      rotationY: provider.rotationY,
      zoom: provider.zoom3d,
      colorForSample: provider.getColorForSample,
      labelForSample: provider.getLabelForSample,
      pointStyle: provider.pointStyle,
      isDark: widget.isDark,
      hoveredIndex: provider.hoveredPointIndex,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final delta = event.scrollDelta.dy > 0 ? -0.1 : 0.1;
              provider.setZoom3d(provider.zoom3d + delta);
            }
          },
          child: GestureDetector(
            onPanUpdate: (details) {
              const sensitivity = 0.01;
              provider.setRotation(
                provider.rotationX - details.delta.dy * sensitivity,
                provider.rotationY + details.delta.dx * sensitivity,
              );
            },
            child: MouseRegion(
              onHover: (event) => _onHover(event.localPosition),
              onExit: (_) => provider.setHoveredPoint(null, null),
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _painter,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onHover(Offset position) {
    final painter = _painter;
    if (painter == null || painter.projectedPositions.isEmpty) return;

    const hitRadius = 15.0;
    int? nearest;
    double nearestDist = hitRadius;

    for (var i = 0; i < painter.projectedPositions.length; i++) {
      final d = (painter.projectedPositions[i] - position).distance;
      if (d < nearestDist) {
        nearestDist = d;
        nearest = widget.data.scores[i].ci;
      }
    }

    widget.provider.setHoveredPoint(nearest, nearest != null ? position : null);
  }
}
