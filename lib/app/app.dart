import 'package:flutter/material.dart';
import 'router.dart';
import '../widgets/no_internet_banner.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Obra Livre',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),

        // ==========================================================
        // TAMANHO GLOBAL DAS LETRAS
        // ==========================================================
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 36),
          displayMedium: TextStyle(fontSize: 32),
          displaySmall: TextStyle(fontSize: 28),

          headlineLarge: TextStyle(fontSize: 26),
          headlineMedium: TextStyle(fontSize: 24),
          headlineSmall: TextStyle(fontSize: 22),

          titleLarge: TextStyle(fontSize: 21),
          titleMedium: TextStyle(fontSize: 19),
          titleSmall: TextStyle(fontSize: 17),

          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),

          labelLarge: TextStyle(fontSize: 16),
          labelMedium: TextStyle(fontSize: 14),
          labelSmall: TextStyle(fontSize: 13),
        ),
      ),

      builder: (context, child) {
        return NoInternetBanner(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

