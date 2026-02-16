import 'package:flutter/material.dart';
import '../../core/utils/web_download.dart';
import '../../di/service_locator.dart';
import '../../domain/models/pca_data.dart';
import '../../domain/services/data_service.dart';

class AppStateProvider extends ChangeNotifier {
  final DataService _dataService;

  AppStateProvider({DataService? dataService})
      : _dataService = dataService ?? serviceLocator<DataService>();

  // --- Data loading state ---
  bool _isLoading = false;
  String? _error;
  PcaData? _data;

  bool get isLoading => _isLoading;
  String? get error => _error;
  PcaData? get data => _data;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _dataService.loadData();
      _updateColorMapping();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- VIEW: Mode (segmented button) ---
  ViewMode _viewMode = ViewMode.scores3d;
  ViewMode get viewMode => _viewMode;
  void setViewMode(ViewMode value) {
    _viewMode = value;
    notifyListeners();
  }

  // --- APPEARANCE: Color By (dropdown) ---
  String _colorBy = 'Supergroup';
  String get colorBy => _colorBy;
  void setColorBy(String value) {
    _colorBy = value;
    _updateColorMapping();
    notifyListeners();
  }

  // --- APPEARANCE: Label By (dropdown) ---
  String _labelBy = 'Supergroup';
  String get labelBy => _labelBy;
  void setLabelBy(String value) {
    _labelBy = value;
    notifyListeners();
  }

  // --- DISPLAY: Point Style (dropdown) ---
  PointStyle _pointStyle = PointStyle.labels;
  PointStyle get pointStyle => _pointStyle;
  void setPointStyle(PointStyle value) {
    _pointStyle = value;
    notifyListeners();
  }

  // --- DISPLAY: 3D Axis selection (dropdowns) ---
  String _scores3dXAxis = 'PC1';
  String _scores3dYAxis = 'PC2';
  String _scores3dZAxis = 'PC3';
  String get scores3dXAxis => _scores3dXAxis;
  String get scores3dYAxis => _scores3dYAxis;
  String get scores3dZAxis => _scores3dZAxis;
  void setScores3dXAxis(String value) {
    _scores3dXAxis = value;
    notifyListeners();
  }

  void setScores3dYAxis(String value) {
    _scores3dYAxis = value;
    notifyListeners();
  }

  void setScores3dZAxis(String value) {
    _scores3dZAxis = value;
    notifyListeners();
  }

  // --- COMPONENTS: Num Components (slider) ---
  int _numComponents = 5;
  int get numComponents => _numComponents;
  void setNumComponents(int value) {
    _numComponents = value.clamp(2, _data?.numComponents ?? 5);
    notifyListeners();
  }

  // --- BIPLOT: X Axis (dropdown) ---
  String _biplotXAxis = 'PC1';
  String get biplotXAxis => _biplotXAxis;
  void setBiplotXAxis(String value) {
    _biplotXAxis = value;
    notifyListeners();
  }

  // --- BIPLOT: Y Axis (dropdown) ---
  String _biplotYAxis = 'PC2';
  String get biplotYAxis => _biplotYAxis;
  void setBiplotYAxis(String value) {
    _biplotYAxis = value;
    notifyListeners();
  }

  // --- BIPLOT: Loading Threshold % (slider 0-100) ---
  double _loadingThreshold = 10.0;
  double get loadingThreshold => _loadingThreshold;
  void setLoadingThreshold(double value) {
    _loadingThreshold = value;
    notifyListeners();
  }

  // --- BIPLOT: Loading Zoom % (slider 1-400) ---
  double _loadingZoom = 100.0;
  double get loadingZoom => _loadingZoom;
  void setLoadingZoom(double value) {
    _loadingZoom = value;
    notifyListeners();
  }

  // --- 3D rotation/zoom (gesture-driven, not a panel control) ---
  double _rotationX = 0.3;
  double _rotationY = 0.5;
  double _zoom3d = 1.0;
  double get rotationX => _rotationX;
  double get rotationY => _rotationY;
  double get zoom3d => _zoom3d;
  void setRotation(double x, double y) {
    _rotationX = x;
    _rotationY = y;
    notifyListeners();
  }

  void setZoom3d(double value) {
    _zoom3d = value.clamp(0.3, 5.0);
    notifyListeners();
  }

  // --- Hover state (for tooltip) ---
  int? _hoveredPointIndex;
  Offset? _hoverPosition;
  int? get hoveredPointIndex => _hoveredPointIndex;
  Offset? get hoverPosition => _hoverPosition;
  void setHoveredPoint(int? index, Offset? position) {
    if (_hoveredPointIndex == index) return;
    _hoveredPointIndex = index;
    _hoverPosition = position;
    notifyListeners();
  }

  // --- Color mapping ---
  Map<String, Color> _colorMap = {};
  Map<String, Color> get colorMap => _colorMap;

  static const _palette = [
    Color(0xFF1E40AF), // blue
    Color(0xFFDC2626), // red
    Color(0xFF059669), // green
    Color(0xFFD97706), // amber
    Color(0xFF7C3AED), // purple
    Color(0xFFDB2777), // pink
    Color(0xFF0891B2), // cyan
    Color(0xFF65A30D), // lime
  ];

  void _updateColorMapping() {
    if (_data == null) return;
    final values = _data!.getAnnotationValues(_colorBy);
    _colorMap = {
      for (var i = 0; i < values.length; i++)
        values[i]: _palette[i % _palette.length],
    };
  }

  Color getColorForSample(int ci) {
    if (_data == null) return _palette[0];
    final value = _data!.getAnnotationForSample(ci, _colorBy);
    return _colorMap[value] ?? _palette[0];
  }

  String getLabelForSample(int ci) {
    if (_data == null) return '';
    return _data!.getAnnotationForSample(ci, _labelBy);
  }

  /// Helper: get PC index from label like "PC1" -> 0
  int pcIndex(String pcLabel) => int.parse(pcLabel.substring(2)) - 1;

  // --- ACTIONS: Save state ---
  bool _hasSaved = false;
  bool get hasSaved => _hasSaved;
  void savePcaResults() {
    if (_data == null) return;
    _generateAndDownloadCsv();
    _hasSaved = true;
    notifyListeners();
  }

  /// Generate Tercen cross-tab CSV: every .ri × .ci combination.
  /// Columns: ds200.PC1..PC5, ds200.X1..X5, .ri, .ci
  void _generateAndDownloadCsv() {
    final data = _data!;
    final nc = data.numComponents;
    final buf = StringBuffer();

    // Header
    final pcHeaders = List.generate(nc, (i) => '"ds200.PC${i + 1}"');
    final xHeaders = List.generate(nc, (i) => '"ds200.X${i + 1}"');
    buf.writeln('${pcHeaders.join(",")},${xHeaders.join(",")},".ri",".ci"');

    // Cross-tab: one row per .ri × .ci
    for (final loading in data.loadings) {
      for (final score in data.scores) {
        final pcValues = List.generate(nc, (i) => loading[i].toString());
        final xValues = List.generate(nc, (i) => score[i].toString());
        buf.writeln(
            '${pcValues.join(",")},${xValues.join(",")},${loading.ri},${score.ci}');
      }
    }

    downloadFile(buf.toString(), 'pca_results.csv');
  }
}
