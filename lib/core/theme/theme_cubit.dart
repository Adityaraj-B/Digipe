import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app-wide [ThemeMode] and persists it across restarts.
///
/// Usage from any widget:
///   ```dart
///   // Read current mode
///   context.watch<ThemeCubit>().state
///
///   // Toggle
///   context.read<ThemeCubit>().toggle();
///
///   // Set explicitly
///   context.read<ThemeCubit>().setMode(ThemeMode.dark);
///   ```
class ThemeCubit extends Cubit<ThemeMode> {
  static const _prefKey = 'digipe_theme_mode';

  ThemeCubit() : super(ThemeMode.light);

  /// Call once after [SharedPreferences] is available to restore the saved
  /// preference. Defaults to [ThemeMode.system] if no preference is stored.
  Future<void> init(SharedPreferences prefs) async {
    final saved = prefs.getString(_prefKey);
    final mode = switch (saved) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    emit(mode);
  }

  /// Flip between light ↔ dark. If currently system, switches to light.
  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  /// Set an explicit [ThemeMode] and persist the choice.
  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  /// Whether the app is currently in dark mode (either explicit or system
  /// resolving to dark). Used for quick boolean checks in the UI.
  bool isDark(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}
