import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ColorLegend extends StatelessWidget {
  final Map<String, Color> colorMap;
  final bool isDark;

  const ColorLegend({super.key, required this.colorMap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (colorMap.isEmpty) return const SizedBox.shrink();

    final bgColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.92),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: colorMap.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(entry.key, style: AppTextStyles.bodySmall.copyWith(color: textColor)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
