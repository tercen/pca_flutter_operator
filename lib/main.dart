import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Mock/Real switching ---
  // Default: mock mode. Set USE_MOCKS=false for Tercen integration.
  const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

  if (useMocks) {
    setupServiceLocator(useMocks: true);
  } else {
    // Phase 3: Uncomment to initialize Tercen context.
    // Also add these imports at the top of the file:
    //   import 'package:sci_tercen_client/sci_service_factory_web.dart';
    //   import 'package:sci_tercen_context/sci_tercen_context.dart';
    //
    // final taskId = Uri.base.queryParameters['taskId'];
    // if (taskId == null || taskId.isEmpty) {
    //   runApp(_buildErrorApp('Missing taskId parameter'));
    //   return;
    // }
    //
    // try {
    //   final factory = await createServiceFactoryForWebApp();
    //   final ctx = await tercenCtx(serviceFactory: factory, taskId: taskId);
    //   setupServiceLocator(useMocks: false, ctx: ctx);
    // } catch (e) {
    //   debugPrint('Tercen init failed: $e — falling back to mocks');
    //   setupServiceLocator(useMocks: true);
    // }

    // Until Phase 3, fall back to mocks
    setupServiceLocator(useMocks: true);
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(PcaExplorerApp(prefs: prefs));
}

class PcaExplorerApp extends StatelessWidget {
  final SharedPreferences prefs;

  const PcaExplorerApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'PCA Explorer',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
