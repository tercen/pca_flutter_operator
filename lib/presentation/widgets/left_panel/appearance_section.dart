import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class AppearanceSection extends StatelessWidget {
  final bool showLabelBy;

  const AppearanceSection({super.key, this.showLabelBy = true});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final labelColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final fields = provider.data?.annotationFields ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color By dropdown
        Text('Color By', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            value: fields.contains(provider.colorBy) ? provider.colorBy : fields.firstOrNull,
            decoration: const InputDecoration(),
            items: fields
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (value) {
              if (value != null) provider.setColorBy(value);
            },
          ),
        ),

        // Label By dropdown (conditionally visible)
        if (showLabelBy) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Label By', style: AppTextStyles.label.copyWith(color: labelColor)),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              value: fields.contains(provider.labelBy) ? provider.labelBy : fields.firstOrNull,
              decoration: const InputDecoration(),
              items: fields
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (value) {
                if (value != null) provider.setLabelBy(value);
              },
            ),
          ),
        ],
      ],
    );
  }
}
