import 'package:flutter/material.dart';

import 'core/presentation/widgets/debug_inspector_overlay.dart';
import 'core/services/debug_logger.dart';
import 'core/services/user_profile_service.dart';
import 'core/stats/stats_repository.dart';
import 'features/la_caida/economy/player_session.dart';
import 'features/la_caida/economy/player_stats_model.dart';
import 'features/la_caida/presentation/caida_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicialización de captura global de errores y diagnósticos (DebugLogger)
  DebugLogger.initialize();

  // 2. Precarga persistente de datos del usuario, sesión de La Caída y estadísticas
  final statsRepository = SharedPrefsStatsRepository();
  await statsRepository.load();
  await UserProfileService().load();
  await PlayerSession.load();
  await PlayerStatsModel.shared.load();

  runApp(CaidaGoApp(statsRepository: statsRepository));
}

/// Aplicación principal CaidaGO - Juego Tradicional de Naipes y Economía VIP.
class CaidaGoApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final StatsRepository statsRepository;

  const CaidaGoApp({super.key, required this.statsRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CaidaGO - La Caída Tradicional',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B131E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0284C7),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF141F2D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131F2E),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      builder: (context, child) {
        // Envolvemos toda la aplicación en el overlay flotante de diagnóstico y bugs
        return DebugInspectorOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const CaidaSplashScreen(),
    );
  }
}
