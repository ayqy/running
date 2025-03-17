import 'package:flutter/material.dart';

// 主题类型枚举
enum ThemeType {
  light,
  dark,
}

class ThemeColors {
  // 主题类型
  static const ThemeType currentTheme = ThemeType.dark;

  // 获取当前主题的颜色
  static Color get primaryColor => _getThemeColor(_primaryColors);
  static Color get backgroundColor => _getThemeColor(_backgroundColors);
  static Color get valueTextColor => _getThemeColor(_valueTextColors);
  static Color get regularTextColor => _getThemeColor(_regularTextColors);
  static Color get dividerColor => _getThemeColor(_dividerColors);
  static Color get cardColor => _getThemeColor(_cardColors);
  static Color get barColor => _getThemeColor(_barColors);
  static Color get selectedColor => _getThemeColor(_selectedColors);
  
  // 获取导航栏渐变色
  static List<Color> get navBarGradientColors => 
      currentTheme == ThemeType.dark ? 
      [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)] : 
      [const Color(0xFF64D5A3), const Color(0xFF5CC99F)];

  // 获取个人页面头部渐变背景色
  static List<Color> get profileHeaderGradientColors =>
      currentTheme == ThemeType.dark ?
      [const Color(0xFF1A1A1A), const Color(0xFF2D3A30), const Color(0xFF1E3323)] :
      [const Color(0xFF64D5A3), const Color(0xFF5CC99F)];

  // 获取指定主题色值
  static Color _getThemeColor(Map<ThemeType, Color> themeColors) {
    return themeColors[currentTheme] ?? themeColors[ThemeType.light]!;
  }

  // 各主题下的主色调
  static final Map<ThemeType, Color> _primaryColors = {
    ThemeType.light: const Color(0xfff55555),
    ThemeType.dark: const Color(0xFF1A1A1A),
  };

  // 各主题下的背景色
  static final Map<ThemeType, Color> _backgroundColors = {
    ThemeType.light: const Color(0xfff6f7f7),
    ThemeType.dark: const Color(0xFF1A1A1A),
  };

  // 各主题下的数值文本颜色
  static final Map<ThemeType, Color> _valueTextColors = {
    ThemeType.light: Colors.black,
    ThemeType.dark: const Color(0xFFFFFFFF),
  };

  // 各主题下的普通文本颜色
  static final Map<ThemeType, Color> _regularTextColors = {
    ThemeType.light: Colors.grey,
    ThemeType.dark: const Color(0xFFB0B0B0),
  };

  // 各主题下的分隔线颜色
  static final Map<ThemeType, Color> _dividerColors = {
    ThemeType.light: Colors.grey.withOpacity(0.3),
    ThemeType.dark: const Color(0xFF3D3D3D),
  };

  // 各主题下的卡片颜色
  static final Map<ThemeType, Color> _cardColors = {
    ThemeType.light: Colors.white,
    ThemeType.dark: const Color(0xFF2D2D2D),
  };

  // 各主题下的条形图颜色
  static final Map<ThemeType, Color> _barColors = {
    ThemeType.light: const Color(0xffeeeeee),
    ThemeType.dark: const Color(0xFF3D3D3D),
  };

  // 各主题下的RadioBox选中状态颜色
  static final Map<ThemeType, Color> _selectedColors = {
    ThemeType.light: const Color(0xFF4CAF50), // 浅色主题下的绿色
    ThemeType.dark: const Color(0xFF64D5A3), // 深色主题下的绿色
  };
}