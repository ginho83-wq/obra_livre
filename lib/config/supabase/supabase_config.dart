import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  // ==========================================================
  // SUPABASE URL
  // ==========================================================

  static const String url =
      'https://xqwgnbrgyjpfwdybguba.supabase.co';

  // ==========================================================
  // SUPABASE PUBLISHABLE KEY
  // ==========================================================

  static const String anonKey =
      'sb_publishable_0SSiSm4QrVzU-9aBZRuz3A_PKJOzRHx';

  // ==========================================================
  // INICIALIZAÇÃO DO SUPABASE
  // ==========================================================

  static Future<void> initialize() async {
    if (url.trim().isEmpty) {
      throw Exception(
        'SUPABASE_URL não foi configurada.',
      );
    }

    if (anonKey.trim().isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY não foi configurada.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // ==========================================================
  // CLIENTE SUPABASE
  // ==========================================================

  static SupabaseClient get client {
    return Supabase.instance.client;
  }
}

