import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'repository_model.dart';

class Settings extends ChangeNotifier {
  static const String _lastRepositoryPathKey = 'last_repository_path';
  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  final SharedPreferences _prefs;

  Settings._(this._prefs);

  static Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings._(prefs);
  }

  String? get lastRepositoryPath => _prefs.getString(_lastRepositoryPathKey);

  Future<void> setLastRepositoryPath(String? path) async {
    if (path == null) {
      await _prefs.remove(_lastRepositoryPathKey);
    } else {
      await _prefs.setString(_lastRepositoryPathKey, path);
    }
    notifyListeners();
  }

  Future<Repository?> loadLastRepository() async {
    final path = lastRepositoryPath;
    if (path == null) return null;
    return Repository.load(path);
  }

  ThemeMode get themeMode {
    final value = _prefs.getString(_themeModeKey);
    if (value == null) return ThemeMode.system;

    return ThemeMode.values.firstWhere(
      (mode) => mode.toString() == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.toString());
    notifyListeners();
  }

  String get locale {
    return _prefs.getString(_localeKey) ?? 'zh';
  }

  Future<void> setLocale(String locale) async {
    await _prefs.setString(_localeKey, locale);
    notifyListeners();
  }
}
