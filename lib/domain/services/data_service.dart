import '../models/pca_data.dart';

abstract class DataService {
  Future<PcaData> loadData();
  Future<void> saveResults(PcaData data);
}
