import 'package:get_it/get_it.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' show ServiceFactory;
import '../domain/services/data_service.dart';
import '../implementations/services/mock_data_service.dart';
import '../implementations/services/tercen_data_service.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator({
  bool useMocks = true,
  ServiceFactory? factory,
  String? taskId,
}) {
  if (serviceLocator.isRegistered<DataService>()) return;

  if (useMocks) {
    serviceLocator.registerLazySingleton<DataService>(
      () => MockDataService(),
    );
  } else {
    serviceLocator.registerSingleton<ServiceFactory>(factory!);
    serviceLocator.registerLazySingleton<DataService>(
      () => TercenDataService(factory, taskId!),
    );
  }
}
