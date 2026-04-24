import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appSettingsProvider = NotifierProvider<AppSettingsController, AppSettingsState>(AppSettingsController.new);

class AppSettingsState {
  const AppSettingsState({
    this.themeMode = ThemeMode.light,
  });

  final ThemeMode themeMode;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppSettingsController extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    return const AppSettingsState();
  }

  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }
}
