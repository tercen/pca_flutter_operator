import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class ComponentsSection extends StatelessWidget {
  const ComponentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final labelColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final maxPc = provider.data?.numComponents ?? 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Number of Components', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: provider.numComponents.toDouble(),
                min: 2,
                max: maxPc.toDouble(),
                divisions: maxPc - 2,
                onChanged: (v) => provider.setNumComponents(v.round()),
              ),
            ),
            SizedBox(
              width: 24,
              child: Text(
                provider.numComponents.toString(),
                style: AppTextStyles.body.copyWith(color: labelColor),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
