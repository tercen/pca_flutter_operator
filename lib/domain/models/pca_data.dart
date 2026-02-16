/// View mode enum
enum ViewMode { scores3d, pairs, biplot, variation }

/// Point style for 3D view
enum PointStyle { labels, spheres }

/// A single PCA score (one observation projected into PC space)
class PcaScore {
  final int ci;
  final List<double> values;

  const PcaScore({required this.ci, required this.values});

  double operator [](int pcIndex) => values[pcIndex];
}

/// A single PCA loading (one variable's contribution to PCs)
class PcaLoading {
  final int ri;
  final String variable;
  final List<double> values;

  const PcaLoading({required this.ri, required this.variable, required this.values});

  double operator [](int pcIndex) => values[pcIndex];
}

/// Metadata for one observation (sample)
class SampleAnnotation {
  final int ci;
  final String instrumentUnit;
  final String supergroup;
  final String testCondition;
  final String barcode;
  final double row;

  const SampleAnnotation({
    required this.ci,
    required this.instrumentUnit,
    required this.supergroup,
    required this.testCondition,
    required this.barcode,
    required this.row,
  });
}

/// Variance explained by each PC
class PcVariance {
  final String label;
  final double variance;
  final double percent;

  const PcVariance({required this.label, required this.variance, required this.percent});
}

/// Complete PCA dataset
class PcaData {
  final List<PcaScore> scores;
  final List<PcaLoading> loadings;
  final List<PcVariance> variance;
  final List<SampleAnnotation> annotations;
  final int numComponents;

  const PcaData({
    required this.scores,
    required this.loadings,
    required this.variance,
    required this.annotations,
    required this.numComponents,
  });

  /// Available annotation field names for dropdowns
  List<String> get annotationFields =>
      ['Supergroup', 'Test Condition', 'Instrument Unit', 'Barcode'];

  /// PC labels for dropdowns
  List<String> get pcLabels =>
      List.generate(numComponents, (i) => 'PC${i + 1}');

  /// Get all unique values for a given annotation field
  List<String> getAnnotationValues(String field) {
    switch (field) {
      case 'Supergroup':
        return annotations.map((a) => a.supergroup).toSet().toList()..sort();
      case 'Test Condition':
        return annotations.map((a) => a.testCondition).toSet().toList()..sort();
      case 'Instrument Unit':
        return annotations.map((a) => a.instrumentUnit).toSet().toList()..sort();
      case 'Barcode':
        return annotations.map((a) => a.barcode).toSet().toList()..sort();
      default:
        return [];
    }
  }

  /// Get annotation value for a sample by field name
  String getAnnotationForSample(int ci, String field) {
    final ann = annotations.firstWhere((a) => a.ci == ci);
    switch (field) {
      case 'Supergroup':
        return ann.supergroup;
      case 'Test Condition':
        return ann.testCondition;
      case 'Instrument Unit':
        return ann.instrumentUnit;
      case 'Barcode':
        return ann.barcode;
      default:
        return '';
    }
  }
}
