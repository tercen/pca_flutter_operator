import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/pca_data.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class DisplaySection extends StatelessWidget {
  const DisplaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final labelColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final pcLabels = provider.data?.pcLabels ?? ['PC1', 'PC2', 'PC3'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Point Style',
            style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<PointStyle>(
            value: provider.pointStyle,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(
                  value: PointStyle.labels, child: Text('Labels')),
              DropdownMenuItem(
                  value: PointStyle.spheres, child: Text('Spheres')),
            ],
            onChanged: (value) {
              if (value != null) provider.setPointStyle(value);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('X Axis',
            style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            value: provider.scores3dXAxis,
            decoration: const InputDecoration(),
            items: pcLabels
                .map((pc) => DropdownMenuItem(value: pc, child: Text(pc)))
                .toList(),
            onChanged: (value) {
              if (value != null) provider.setScores3dXAxis(value);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Y Axis',
            style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            value: provider.scores3dYAxis,
            decoration: const InputDecoration(),
            items: pcLabels
                .map((pc) => DropdownMenuItem(value: pc, child: Text(pc)))
                .toList(),
            onChanged: (value) {
              if (value != null) provider.setScores3dYAxis(value);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Z Axis',
            style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            value: provider.scores3dZAxis,
            decoration: const InputDecoration(),
            items: pcLabels
                .map((pc) => DropdownMenuItem(value: pc, child: Text(pc)))
                .toList(),
            onChanged: (value) {
              if (value != null) provider.setScores3dZAxis(value);
            },
          ),
        ),
      ],
    );
  }
}
