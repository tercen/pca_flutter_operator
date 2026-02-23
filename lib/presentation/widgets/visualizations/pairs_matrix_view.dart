import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../domain/models/pca_data.dart';
import '../../painters/pairs_matrix_painter.dart';
import '../../providers/app_state_provider.dart';
import '../color_legend.dart';

class PairsMatrixView extends StatelessWidget {
  final PcaData data;
  final AppStateProvider provider;
  final bool isDark;

  const PairsMatrixView({
    super.key,
    required this.data,
    required this.provider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final n = provider.numComponents;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final diagBg = isDark ? const Color(0xFF374151) : AppColors.neutral100;
    // Visible tick color — neutral700 in light mode, neutral400 in dark
    final tickColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF374151);

    // Fixed layout constants
    const outerLabelW = 28.0; // left row-label column
    const outerLabelH = 22.0; // top col-label row
    const legendGap = 16.0;
    const legendReserve = 130.0; // width reserved for legend
    const padding = 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute the largest square grid that fits, leaving room for labels
        // and the legend alongside.
        final availW =
            constraints.maxWidth - padding * 2 - outerLabelW - legendGap - legendReserve;
        final availH = constraints.maxHeight - padding * 2 - outerLabelH;
        final gridSize = min(availW, availH).clamp(0.0, double.infinity);

        // ── Build the column-header + grid block ───────────────────────────
        final matrixBlock = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column (PC) labels above the grid
            Row(
              children: [
                SizedBox(width: outerLabelW),
                SizedBox(
                  width: gridSize,
                  height: outerLabelH,
                  child: Row(
                    children: List.generate(
                      n,
                      (col) => Expanded(
                        child: Center(
                          child: Text(
                            'PC${col + 1}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Row labels (left) + the grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rotated row (PC) labels
                SizedBox(
                  width: outerLabelW,
                  height: gridSize,
                  child: Column(
                    children: List.generate(
                      n,
                      (row) => Expanded(
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              'PC${row + 1}',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // The cell grid
                SizedBox(
                  width: gridSize,
                  height: gridSize,
                  child: Column(
                    children: List.generate(
                      n,
                      (row) => Expanded(
                        child: Row(
                          children: List.generate(n, (col) {
                            if (row == col) {
                              // Diagonal: distinct background + PC label
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: diagBg,
                                    border:
                                        Border.all(color: borderColor, width: 1.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'PC${row + 1}',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Off-diagonal scatter cell.
                            // Y ticks on rightmost column (pointing right),
                            // X ticks on bottom row (pointing down).
                            return Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: borderColor, width: 1.0),
                                ),
                                child: CustomPaint(
                                  painter: PairsCellPainter(
                                    scores: data.scores,
                                    pcIndexX: col,
                                    pcIndexY: row,
                                    colorForSample: provider.getColorForSample,
                                    showYTicks: col == n - 1,
                                    showXTicks: row == n - 1,
                                    tickColor: tickColor,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

        // ── Centre the matrix+legend group within the available space ──────
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                matrixBlock,
                const SizedBox(width: legendGap),
                // Legend stays immediately adjacent — never floats to edge
                ColorLegend(colorMap: provider.colorMap, isDark: isDark),
              ],
            ),
          ),
        );
      },
    );
  }
}
