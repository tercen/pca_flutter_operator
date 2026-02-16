import 'package:get_it/get_it.dart';
import '../domain/services/data_service.dart';
import '../implementations/services/mock_data_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Register services. Called once from main().
///
/// Mock mode: registers MockDataService.
/// Real mode: registers Tercen context + real data service.
///
/// Phase 3 adds:
///   import 'package:sci_tercen_context/sci_tercen_context.dart';
///   setupServiceLocator(useMocks: false, ctx: ctx);
///   // where ctx = await tercenCtx(serviceFactory: factory, taskId: taskId)
void setupServiceLocator({
  bool useMocks = true,
  // Phase 3: uncomment to accept context
  // AbstractOperatorContext? ctx,
}) {
  if (serviceLocator.isRegistered<DataService>()) return;

  if (useMocks) {
    serviceLocator.registerLazySingleton<DataService>(
      () => MockDataService(),
    );
  }
  // Phase 3: add else branch:
  // else {
  //   serviceLocator.registerSingleton<AbstractOperatorContext>(ctx!);
  //   serviceLocator.registerLazySingleton<DataService>(
  //     () => TercenDataService(ctx),
  //   );
  // }
}
