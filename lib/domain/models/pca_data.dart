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

/// Metadata for one observation (sample) — dynamic fields from Tercen cselect()
class SampleAnnotation {
  final int ci;
  final Map<String, String> fields;

  const SampleAnnotation({required this.ci, required this.fields});

  String operator [](String fieldName) => fields[fieldName] ?? '';
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
  final List<String> annotationFields;
  final String defaultColorBy;

  const PcaData({
    required this.scores,
    required this.loadings,
    required this.variance,
    required this.annotations,
    required this.numComponents,
    required this.annotationFields,
    required this.defaultColorBy,
  });

  /// PC labels for dropdowns
  List<String> get pcLabels =>
      List.generate(numComponents, (i) => 'PC${i + 1}');

  /// Get all unique values for a given annotation field
  List<String> getAnnotationValues(String field) {
    return annotations.map((a) => a[field]).where((v) => v.isNotEmpty).toSet().toList()..sort();
  }

  /// Get annotation value for a sample by field name
  String getAnnotationForSample(int ci, String field) {
    final ann = annotations.firstWhere((a) => a.ci == ci,
        orElse: () => SampleAnnotation(ci: ci, fields: {}));
    return ann[field];
  }
}
