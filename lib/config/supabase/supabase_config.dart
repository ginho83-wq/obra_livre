import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url =
      'https://xqwgnbrgyjpfwdybguba.supabase.co';

  static const String anonKey =
      'sb_publishable_0SSiSm4QrVzU-9aBZRuz3A_PKJOzRHx';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client {
    return Supabase.instance.client;
  }
}
