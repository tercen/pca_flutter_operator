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
    // Distinct fill for diagonal label cells
    final diagBg = isDark ? const Color(0xFF374151) : AppColors.neutral100;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square matrix with outer PC labels
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Reserve space for the outer axis labels
                const outerLabelW = 28.0; // left: row (PC) labels
                const outerLabelH = 22.0; // top: column (PC) labels

                final availW = constraints.maxWidth - outerLabelW;
                final availH = constraints.maxHeight - outerLabelH;
                // Constrain to square
                final gridSize = min(availW, availH);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top row: spacer + column PC labels ──────────────────
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

                    // ── Matrix rows + left row PC labels ────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: rotated row labels
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

                        // The grid
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
                                            border: Border.all(
                                                color: borderColor, width: 1.0),
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

                                    // Off-diagonal: scatter cell
                                    // Show Y ticks on leftmost column,
                                    // X ticks on bottom row
                                    return Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: borderColor, width: 1.0),
                                        ),
                                        child: CustomPaint(
                                          painter: PairsCellPainter(
                                            scores: data.scores,
                                            pcIndexX: col,
                                            pcIndexY: row,
                                            colorForSample:
                                                provider.getColorForSample,
                                            showYTicks: col == 0,
                                            showXTicks: row == n - 1,
                                            tickColor: borderColor,
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
              },
            ),
          ),

          // ── Color legend to the right, outside the matrix ──────────────
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: ColorLegend(
              colorMap: provider.colorMap,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}
