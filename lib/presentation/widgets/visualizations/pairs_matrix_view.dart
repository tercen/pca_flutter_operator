import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/pca_data.dart';
import '../../painters/pairs_matrix_painter.dart';
import '../../providers/app_state_provider.dart';

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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: List.generate(n, (row) {
          return Expanded(
            child: Row(
              children: List.generate(n, (col) {
                if (row == col) {
                  // Diagonal: show PC label
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          'PC${row + 1}',
                          style: AppTextStyles.label.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 0.5),
                    ),
                    child: CustomPaint(
                      painter: PairsCellPainter(
                        scores: data.scores,
                        pcIndexX: col,
                        pcIndexY: row,
                        colorForSample: provider.getColorForSample,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
