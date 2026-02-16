import '../models/pca_data.dart';

abstract class DataService {
  Future<PcaData> loadData();
}
