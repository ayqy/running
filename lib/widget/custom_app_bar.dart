import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../const/ui.dart';
import '../const/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.leading,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColors>(
      builder: (context, theme, child) => AppBar(
        toolbarHeight: UIConsts.APPBAR_TOOLBAR_HEIGHT,
        title: Text(title),
        leading: leading,
        bottom: bottom,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: ThemeColors.navBarGradientColors
            ),
          ),
        ),
        foregroundColor: ThemeColors.regularTextColor,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(UIConsts.APPBAR_TOOLBAR_HEIGHT + (bottom?.preferredSize.height ?? 0.0));

}