import 'package:dualio/core/config/app_config.dart';
import 'package:dualio/core/supabase/supabase_bootstrap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMagicLink(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      throw const AuthConfigurationException('Email is required.');
    }

    final client = SupabaseBootstrap.client;
    if (client == null) {
      throw const AuthConfigurationException('Supabase is not configured yet.');
    }

    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      await client.auth.signInWithOtp(
        email: normalized,
        emailRedirectTo: AppConfig.authRedirectUri,
      );
    });
    state.requireValue;
  }

  Future<void> signInWithGoogle() async {
    final client = SupabaseBootstrap.client;
    if (client == null) {
      throw const AuthConfigurationException('Supabase is not configured yet.');
    }

    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(() async {
      final launched = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.authRedirectUri,
      );
      if (!launched) {
        throw const AuthConfigurationException('Could not open Google sign-in.');
      }
    });
    state.requireValue;
  }
}

class AuthConfigurationException implements Exception {
  const AuthConfigurationException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
