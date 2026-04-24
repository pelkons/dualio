import 'package:dualio/app/dualio_app.dart';
import 'package:dualio/core/config/app_config.dart';
import 'package:dualio/core/supabase/supabase_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize(AppConfig.current);
  runApp(const ProviderScope(child: DualioApp()));
}
