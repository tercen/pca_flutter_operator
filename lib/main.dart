import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sci_tercen_client/sci_service_factory_web.dart';
import 'package:sci_tercen_context/sci_tercen_context.dart' hide Colors;

import 'core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: false);

  AbstractOperatorContext? ctx;

  if (!useMocks) {
    try {
      final taskId = Uri.base.queryParameters['taskId'];
      if (taskId == null || taskId.isEmpty) {
        runApp(_buildErrorApp('Missing taskId parameter'));
        return;
      }
      final factory = await createServiceFactoryForWebApp();
      ctx = await tercenCtx(serviceFactory: factory, taskId: taskId);
    } catch (e) {
      debugPrint('Tercen init failed: $e');
    }
  }

  setupServiceLocator(
    useMocks: ctx == null,
    ctx: ctx,
  );

  final prefs = await SharedPreferences.getInstance();
  runApp(PcaExplorerApp(prefs: prefs));
}

Widget _buildErrorApp(String message) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 18),
        ),
      ),
    ),
  );
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
