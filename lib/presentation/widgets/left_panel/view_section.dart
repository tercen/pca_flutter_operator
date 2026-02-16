import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/pca_data.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class ViewSection extends StatelessWidget {
  const ViewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final labelColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ViewMode>(
            segments: const [
              ButtonSegment(value: ViewMode.scores3d, label: Text('3D')),
              ButtonSegment(value: ViewMode.pairs, label: Text('Pairs')),
              ButtonSegment(value: ViewMode.biplot, label: Text('Biplot')),
              ButtonSegment(value: ViewMode.variation, label: Text('Var')),
            ],
            selected: {provider.viewMode},
            onSelectionChanged: (values) {
              provider.setViewMode(values.first);
            },
            showSelectedIcon: false,
          ),
        ),
      ],
    );
  }
}
