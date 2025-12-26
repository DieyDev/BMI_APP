import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  // Tạo Singleton để có thể gọi ở bất cứ đâu
  static final ThemeService instance = ThemeService._();

  ThemeService._(); // Constructor ẩn

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Hàm tải cài đặt khi mở App
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners(); // Báo hiệu đã tải xong
  }

  // Hàm đổi chế độ
  Future<void> toggleTheme(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = isOn;
    await prefs.setBool('isDarkMode', isOn);
    notifyListeners(); // Báo hiệu cho main.dart vẽ lại
  }
}