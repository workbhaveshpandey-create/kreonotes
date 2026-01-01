import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeStr = prefs.getString(_themeKey);
    if (themeStr != null) {
      if (themeStr == 'light')
        emit(ThemeMode.light);
      else if (themeStr == 'dark')
        emit(ThemeMode.dark);
      else
        emit(ThemeMode.system);
    }
  }

  Future<void> updateTheme(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    String type = 'system';
    if (mode == ThemeMode.light)
      type = 'light';
    else if (mode == ThemeMode.dark)
      type = 'dark';
    await prefs.setString(_themeKey, type);
  }
}
