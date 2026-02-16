import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sci_tercen_context/sci_tercen_context.dart';

import '../../core/math/pca_computation.dart';
import '../../domain/models/pca_data.dart';
import '../../domain/services/data_service.dart';
import 'mock_data_service.dart';

class TercenDataService implements DataService {
  final AbstractOperatorContext _ctx;
  final MockDataService _mockService = MockDataService();

  TercenDataService(this._ctx);

  @override
  Future<PcaData> loadData() async {
    try {
      // 1. Read operator properties
      final scaleSpots =
          (await _ctx.opStringValue('Scale Spots', defaultValue: 'No')) ==
              'Yes';
      final nComponentsProp =
          (await _ctx.opDoubleValue('Number of Components', defaultValue: 5))
              .toInt();
      final subtractComponent =
          (await _ctx.opDoubleValue('Subtract component', defaultValue: 0))
              .toInt();

      // 2. Fetch three tables
      await _ctx.progress('Loading data...', actual: 0, total: 5);
      final qtData = await _ctx.select(names: ['.y', '.ci', '.ri']);
      await _ctx.progress('Loading column metadata...', actual: 1, total: 5);
      final colData = await _ctx.cselect();
      await _ctx.progress('Loading row metadata...', actual: 2, total: 5);
      final rowData = await _ctx.rselect();

      // 3. Get color factors for default Color By
      List<String> colorFactors;
      try {
        colorFactors = await _ctx.colors;
      } catch (_) {
        colorFactors = [];
      }

      // 4. Parse qtData arrays
      List ciRaw = [];
      List riRaw = [];
      List<double> yValues = [];
      for (final col in qtData.columns) {
        final values = col.values as List?;
        if (values == null) continue;
        switch (col.name) {
          case '.ci':
            ciRaw = values;
          case '.ri':
            riRaw = values;
          case '.y':
            yValues = values.map((v) => (v as num).toDouble()).toList();
        }
      }

      if (yValues.isEmpty) {
        throw StateError('No .y values returned from ctx.select()');
      }

      // 5. Build unique sorted ci and ri lists
      final uniqueCi = <int>{};
      final uniqueRi = <int>{};
      for (int i = 0; i < ciRaw.length; i++) {
        uniqueCi.add(_toInt(ciRaw[i]));
        uniqueRi.add(_toInt(riRaw[i]));
      }
      final sortedCi = uniqueCi.toList()..sort();
      final sortedRi = uniqueRi.toList()..sort();
      final ciIdx = {
        for (var i = 0; i < sortedCi.length; i++) sortedCi[i]: i,
      };
      final riIdx = {
        for (var i = 0; i < sortedRi.length; i++) sortedRi[i]: i,
      };

      final nObs = sortedCi.length;
      final nVars = sortedRi.length;

      // 6. Build X matrix (n_obs x n_vars)
      final X = List.generate(nObs, (_) => List.filled(nVars, 0.0));
      for (int i = 0; i < ciRaw.length; i++) {
        final ci = _toInt(ciRaw[i]);
        final ri = _toInt(riRaw[i]);
        X[ciIdx[ci]!][riIdx[ri]!] = yValues[i];
      }

      // 7. Compute PCA
      await _ctx.progress('Computing PCA...', actual: 3, total: 5);
      final pcaResult = PcaComputation.compute(
        X: X,
        scale: scaleSpots,
        nComponents: min(nComponentsProp, min(nObs - 1, nVars)),
        subtractComponent: subtractComponent,
      );

      // 8. Build index maps from column/row metadata
      final colMetadata = _buildIndexMap(colData);
      final rowMetadata = _buildIndexMap(rowData);

      // 9. Build scores
      final scores = <PcaScore>[];
      for (int i = 0; i < nObs; i++) {
        scores.add(PcaScore(ci: sortedCi[i], values: pcaResult.scores[i]));
      }

      // 10. Build loadings
      final loadings = <PcaLoading>[];
      for (int j = 0; j < nVars; j++) {
        final ri = sortedRi[j];
        // Variable name from row metadata — pick first non-dot column value
        String varName = 'var_$ri';
        final meta = rowMetadata[j];
        if (meta != null) {
          for (final entry in meta.entries) {
            if (!entry.key.startsWith('.')) {
              varName = _stripNamespace(entry.value.toString());
              break;
            }
          }
        }
        loadings
            .add(PcaLoading(ri: ri, variable: varName, values: pcaResult.loadings[j]));
      }

      // 11. Build variance
      final variance = <PcVariance>[];
      for (int k = 0; k < pcaResult.nComponents; k++) {
        variance.add(PcVariance(
          label: 'PC${k + 1}',
          variance: pcaResult.eigenvalues[k],
          percent: pcaResult.variancePercent[k],
        ));
      }

      // 12. Build annotations from column metadata
      final annotationFieldNames = <String>{};
      // Color factors first
      for (final cf in colorFactors) {
        annotationFieldNames.add(_stripNamespace(cf));
      }
      // All cselect columns (non-system)
      for (final meta in colMetadata.values) {
        for (final key in meta.keys) {
          if (!key.startsWith('.')) {
            annotationFieldNames.add(_stripNamespace(key));
          }
        }
      }

      final fieldList = annotationFieldNames.toList();
      final annotations = <SampleAnnotation>[];
      for (int i = 0; i < nObs; i++) {
        final ci = sortedCi[i];
        final meta = colMetadata[i] ?? {};
        final fields = <String, String>{};
        for (final fieldName in fieldList) {
          String value = '';
          for (final entry in meta.entries) {
            if (_stripNamespace(entry.key) == fieldName) {
              value = entry.value?.toString() ?? '';
              break;
            }
          }
          fields[fieldName] = value;
        }
        annotations.add(SampleAnnotation(ci: ci, fields: fields));
      }

      // 13. Determine default Color By
      String defaultColorBy = fieldList.isNotEmpty ? fieldList.first : '';
      if (colorFactors.isNotEmpty) {
        final stripped = _stripNamespace(colorFactors.first);
        if (fieldList.contains(stripped)) {
          defaultColorBy = stripped;
        }
      }

      await _ctx.progress('Done', actual: 5, total: 5);

      return PcaData(
        scores: scores,
        loadings: loadings,
        variance: variance,
        annotations: annotations,
        numComponents: pcaResult.nComponents,
        annotationFields: fieldList,
        defaultColorBy: defaultColorBy,
      );
    } catch (e) {
      debugPrint('Tercen data loading error: $e');
      await _printDiagnosticReport();
      return _mockService.loadData();
    }
  }

  @override
  Future<void> saveResults(PcaData data) async {
    try {
      await _ctx.progress('Saving results...', actual: 0, total: 3);

      final nc = data.numComponents;
      final nRows = data.loadings.length * data.scores.length;

      // Build flat arrays — one row per ri x ci (loadings repeated across ci, scores repeated across ri)
      final outCi = <int>[];
      final outRi = <int>[];
      final outPc = List.generate(nc, (_) => <double>[]);

      for (final loading in data.loadings) {
        for (final score in data.scores) {
          outRi.add(loading.ri);
          outCi.add(score.ci);
          for (int k = 0; k < nc; k++) {
            outPc[k].add(loading[k]);
          }
        }
      }

      await _ctx.progress('Building table...', actual: 1, total: 3);

      // Namespace prefix for output columns
      final colNames = List.generate(nc, (k) => 'PC${k + 1}');
      final nsMap = await _ctx.addNamespace(colNames);

      final table = Table();
      table.nRows = nRows;

      // System columns (no namespace)
      table.columns.add(AbstractOperatorContext.makeInt32Column('.ci', outCi));
      table.columns.add(AbstractOperatorContext.makeInt32Column('.ri', outRi));

      // Loading columns: PC1..PCn
      for (int k = 0; k < nc; k++) {
        final name = nsMap['PC${k + 1}'] ?? 'PC${k + 1}';
        table.columns.add(AbstractOperatorContext.makeFloat64Column(name, outPc[k]));
      }

      await _ctx.progress('Uploading...', actual: 2, total: 3);
      await _ctx.saveTable(table);
      await _ctx.progress('Done', actual: 3, total: 3);
    } catch (e) {
      debugPrint('Tercen save error: $e');
      await _printDiagnosticReport();
      rethrow;
    }
  }

  // --- Helpers ---

  Map<int, Map<String, dynamic>> _buildIndexMap(Table table) {
    final result = <int, Map<String, dynamic>>{};
    for (final col in table.columns) {
      final values = col.values as List?;
      if (values == null) continue;
      for (int i = 0; i < values.length; i++) {
        result.putIfAbsent(i, () => {});
        result[i]![col.name] = values[i];
      }
    }
    return result;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.parse(v.toString());
  }

  static String _stripNamespace(String name) {
    return name.contains('.') ? name.split('.').last : name;
  }

  Future<void> _printDiagnosticReport() async {
    debugPrint('=== TERCEN DIAGNOSTIC REPORT ===');
    debugPrint('Task: ${_ctx.taskId} (${_ctx.task?.runtimeType})');

    for (final entry in {
      'schema (qtHash)': _ctx.schema,
      'cschema (columnHash)': _ctx.cschema,
      'rschema (rowHash)': _ctx.rschema,
    }.entries) {
      debugPrint('\n--- ${entry.key} ---');
      try {
        final s = await entry.value;
        debugPrint(
            'Rows: ${s.nRows}, Columns: ${s.columns.map((c) => "${c.name}:${c.type}").join(', ')}');
      } catch (e) {
        debugPrint('ERROR: $e');
      }
    }

    try {
      final ns = await _ctx.namespace;
      debugPrint('\nNamespace: $ns');
    } catch (e) {
      debugPrint('\nNamespace ERROR: $e');
    }

    debugPrint('=== END REPORT ===');
  }
}
