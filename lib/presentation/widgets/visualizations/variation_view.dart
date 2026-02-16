import 'package:flutter/material.dart';
import '../../../domain/models/pca_data.dart';
import '../../painters/variation_painter.dart';

class VariationView extends StatelessWidget {
  final PcaData data;
  final bool isDark;

  const VariationView({super.key, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: VariationPainter(
            variance: data.variance,
            isDark: isDark,
          ),
        );
      },
    );
  }
}
