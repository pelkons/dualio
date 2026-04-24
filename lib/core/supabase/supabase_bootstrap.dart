import 'package:dualio/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static Future<void> initialize(AppConfig config) async {
    if (!config.hasSupabase) {
      return;
    }

    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } on StateError {
      return null;
    }
  }
}
