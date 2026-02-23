import 'package:flutter/material.dart';
import '../../../domain/models/pca_data.dart';
import '../../painters/biplot_painter.dart';
import '../../providers/app_state_provider.dart';

class BiplotView extends StatefulWidget {
  final PcaData data;
  final AppStateProvider provider;
  final bool isDark;

  const BiplotView({
    super.key,
    required this.data,
    required this.provider,
    required this.isDark,
  });

  @override
  State<BiplotView> createState() => _BiplotViewState();
}

class _BiplotViewState extends State<BiplotView> {
  BiplotPainter? _painter;
  int? _hoveredLoadingIndex;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    _painter = BiplotPainter(
      scores: widget.data.scores,
      loadings: widget.data.loadings,
      pcIndexX: provider.pcIndex(provider.biplotXAxis),
      pcIndexY: provider.pcIndex(provider.biplotYAxis),
      colorForSample: provider.getColorForSample,
      labelForSample: provider.getLabelForSample,
      loadingThresholdPercent: provider.loadingThreshold,
      loadingZoomPercent: provider.loadingZoom,
      isDark: widget.isDark,
      hoveredIndex: provider.hoveredPointIndex,
      hoveredLoadingIndex: _hoveredLoadingIndex,
    );

    final hintColor = widget.isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) => _onHover(event.localPosition),
          onExit: (_) {
            provider.setHoveredPoint(null, null);
            if (_hoveredLoadingIndex != null) {
              setState(() => _hoveredLoadingIndex = null);
            }
          },
          child: Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _painter,
              ),
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Hover arrow to see label',
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onHover(Offset position) {
    final painter = _painter;
    if (painter == null) return;

    const hitRadius = 15.0;

    // Check score points first
    int? nearestScore;
    double nearestScoreDist = hitRadius;
    for (var i = 0; i < painter.projectedScorePositions.length; i++) {
      final d = (painter.projectedScorePositions[i] - position).distance;
      if (d < nearestScoreDist) {
        nearestScoreDist = d;
        nearestScore = widget.data.scores[i].ci;
      }
    }

    // Check loading arrow tips
    int? nearestLoading;
    double nearestLoadingDist = hitRadius;
    for (var i = 0; i < painter.projectedArrowTips.length; i++) {
      final d = (painter.projectedArrowTips[i] - position).distance;
      if (d < nearestLoadingDist) {
        nearestLoadingDist = d;
        nearestLoading = painter.visibleLoadingIndices[i];
      }
    }

    // Update score hover via provider
    widget.provider
        .setHoveredPoint(nearestScore, nearestScore != null ? position : null);

    // Update loading hover via local state
    if (_hoveredLoadingIndex != nearestLoading) {
      setState(() => _hoveredLoadingIndex = nearestLoading);
    }
  }
}
