import 'package:flutter/material.dart';

import 'core/stats/stats_repository.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final statsRepository = InMemoryStatsRepository();
  runApp(CompendioJuegosApp(statsRepository: statsRepository));
}

/// Aplicación principal Compendio de Juegos Tradicionales de Mesa y Cartas.
class CompendioJuegosApp extends StatelessWidget {
  final StatsRepository statsRepository;

  const CompendioJuegosApp({super.key, required this.statsRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compendio de Juegos Tradicionales',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B131E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0D9488),
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
      home: HomeScreen(statsRepository: statsRepository),
    );
  }
}
