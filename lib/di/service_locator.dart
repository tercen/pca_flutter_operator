import 'package:get_it/get_it.dart';
import 'package:sci_tercen_context/sci_tercen_context.dart';
import '../domain/services/data_service.dart';
import '../implementations/services/mock_data_service.dart';
import '../implementations/services/tercen_data_service.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator({
  bool useMocks = true,
  AbstractOperatorContext? ctx,
}) {
  if (serviceLocator.isRegistered<DataService>()) return;

  if (useMocks) {
    serviceLocator.registerLazySingleton<DataService>(
      () => MockDataService(),
    );
  } else {
    serviceLocator.registerSingleton<AbstractOperatorContext>(ctx!);
    serviceLocator.registerLazySingleton<DataService>(
      () => TercenDataService(ctx),
    );
  }
}
