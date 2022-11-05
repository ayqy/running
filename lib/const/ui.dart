import 'package:flutter/cupertino.dart';

class UIConsts {
  static double APPBAR_TOOLBAR_HEIGHT = 36;
  static Widget APPBAR_FLEXIBLE_SPACE = Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xfffccf31), Color(0xfff55555)]
      ),
    ),
  );

  // 底部面板初始高度 = dashboard配速卡高度 + bar + bar上的间距
  static const double SLIDING_PANEL_INITIAL_HEIGHT = 131 + 5 + 5;
}
