import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

enum GlowEffectType {
  none,
  outerGlow,
  neonBorder,
  innerFill,
}

enum AppSkin {
  bimbomixer,
  synthwave,
  cyberpunk,
  oceanGlass,
  sunset
}

class AppThemeProvider extends ChangeNotifier {
  static const _keyDateFormat = 'date_format';
  static const _keySkin = 'app_skin';
  
  String _dateFormat = 'yyyy-MM-dd';
  AppSkin _currentSkin = AppSkin.bimbomixer;

  String get dateFormat => _dateFormat;
  AppSkin get currentSkin => _currentSkin;

  AppThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _dateFormat = prefs.getString(_keyDateFormat) ?? 'yyyy-MM-dd';
    
    final skinIndex = prefs.getInt(_keySkin) ?? 0;
    if (skinIndex >= 0 && skinIndex < AppSkin.values.length) {
      _currentSkin = AppSkin.values[skinIndex];
    }
    
    notifyListeners();
  }

  Future<void> setDateFormat(String format) async {
    _dateFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDateFormat, format);
    notifyListeners();
  }

  Future<void> setSkin(AppSkin skin) async {
    _currentSkin = skin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySkin, skin.index);
    notifyListeners();
  }

  // --- Dynamic Skin Colors ---

  Color get primaryColor {
    switch (_currentSkin) {
      case AppSkin.bimbomixer: return const Color(0xFFFFD700); // Neon Yellow
      case AppSkin.synthwave: return const Color(0xFFFF00FF);  // Magenta
      case AppSkin.cyberpunk: return const Color(0xFF00FF00);  // Acid Green
      case AppSkin.oceanGlass: return const Color(0xFF00BFFF); // Cyan
      case AppSkin.sunset: return const Color(0xFFFF4500);     // Neon Orange
    }
  }

  Color get secondaryColor {
    switch (_currentSkin) {
      case AppSkin.bimbomixer: return const Color(0xFFFFF033); // Bright Yellow
      case AppSkin.synthwave: return const Color(0xFF00FFFF);  // Cyan
      case AppSkin.cyberpunk: return const Color(0xFF39FF14);  // Bright Green
      case AppSkin.oceanGlass: return const Color(0xFF1E90FF); // Dodger Blue
      case AppSkin.sunset: return const Color(0xFFFFD700);     // Yellow
    }
  }

  LinearGradient get backgroundGradient {
    switch (_currentSkin) {
      case AppSkin.bimbomixer:
        return const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppSkin.synthwave:
        return LinearGradient(
          colors: [const Color(0xFF2A004D), const Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppSkin.cyberpunk:
        return LinearGradient(
          colors: [const Color(0xFF002200), const Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppSkin.oceanGlass:
        return LinearGradient(
          colors: [const Color(0xFF001F3F), const Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppSkin.sunset:
        return LinearGradient(
          colors: [const Color(0xFF3E0000), const Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
  
  Color get glowColor => primaryColor.withValues(alpha: 0.5);
  Color get buttonColor => primaryColor;
  Color get buttonTextColor => const Color(0xFF000000);
  Color get textColor => Colors.white;
  
  Color get cardColor => const Color(0xFF1E1E24); 
  Color get glassBorderColor => primaryColor.withValues(alpha: 0.4); 
  
  GlowEffectType get glowEffectType => GlowEffectType.neonBorder; 
  Color get scaffoldBackgroundColor => const Color(0xFF111111);
  
  Color get cardTextColor => Colors.white;
  Color get primaryTextColor => Colors.white;
  Color get secondaryTextColor => Colors.white70;

  LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
