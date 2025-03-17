import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

class UIConsts {
  static double APPBAR_TOOLBAR_HEIGHT = 36;
  // 导航栏文字颜色
  static Color get APPBAR_TEXT_COLOR => ThemeColors.regularTextColor;
  // 导航栏文字字号
  static const double APPBAR_TEXT_FONT_SIZE = 14.0;
  static Widget APPBAR_FLEXIBLE_SPACE = Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: ThemeColors.navBarGradientColors
      ),
    ),
  );

  // 底部面板初始高度 = dashboard配速卡高度 + bar + bar上的间距
  static const double SLIDING_PANEL_INITIAL_HEIGHT = 131 + 5 + 5;
}
