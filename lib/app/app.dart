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

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      builder: (context, child) {
        return NoInternetBanner(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
