import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//Quản lý chế độ sáng/tối (Light/Dark mode) cho toàn bộ ứng dụng
class ThemeProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _key = 'isDarkMode';

  late Box _box;
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _isDark = _box.get(_key, defaultValue: false);
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    await _box.put(_key, _isDark);
    notifyListeners();
  }
}
