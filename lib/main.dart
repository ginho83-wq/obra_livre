import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'config/supabase/supabase_config.dart';
import 'services/connectivity_service.dart';
import 'app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // HIVE
  // ============================================================

  await Hive.initFlutter();

  // ============================================================
  // SUPABASE
  // ============================================================

  await SupabaseConfig.initialize();

  // ============================================================
  // ROUTER
  // ============================================================

  initializeRouter();

  // ============================================================
  // CONECTIVIDADE
  // ============================================================

  await ConnectivityService.instance.initialize();

  // ============================================================
  // APLICAÇÃO
  // ============================================================

  runApp(const App());
}
