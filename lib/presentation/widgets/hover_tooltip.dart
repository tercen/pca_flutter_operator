import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/pca_data.dart';
import '../providers/app_state_provider.dart';

class HoverTooltip extends StatelessWidget {
  final int sampleIndex;
  final PcaData data;
  final AppStateProvider provider;
  final bool isDark;

  const HoverTooltip({
    super.key,
    required this.sampleIndex,
    required this.data,
    required this.provider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ann = data.annotations.firstWhere((a) => a.ci == sampleIndex);
    final score = data.scores.firstWhere((s) => s.ci == sampleIndex);
    final bgColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show first 2 annotation fields as header
            if (data.annotationFields.length >= 2)
              Text(
                '${ann[data.annotationFields[0]]} / ${ann[data.annotationFields[1]]}',
                style: AppTextStyles.label.copyWith(color: textColor),
              )
            else if (data.annotationFields.isNotEmpty)
              Text(
                ann[data.annotationFields[0]],
                style: AppTextStyles.label.copyWith(color: textColor),
              )
            else
              Text(
                'Sample $sampleIndex',
                style: AppTextStyles.label.copyWith(color: textColor),
              ),
            const SizedBox(height: 2),
            // Show remaining annotation fields (up to 2 more)
            for (var i = 2; i < data.annotationFields.length && i < 4; i++)
              Text(
                '${data.annotationFields[i]}: ${ann[data.annotationFields[i]]}',
                style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
              ),
            const SizedBox(height: 4),
            for (var i = 0; i < data.numComponents && i < 3; i++)
              Text(
                'PC${i + 1}: ${score[i].toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
              ),
          ],
        ),
      ),
    );
  }
}
