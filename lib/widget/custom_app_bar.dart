import 'package:flutter/material.dart';
import '../const/ui.dart';

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
    return AppBar(
      toolbarHeight: UIConsts.APPBAR_TOOLBAR_HEIGHT,
      title: Text(title),
      leading: leading,
      bottom: bottom,
      flexibleSpace: UIConsts.APPBAR_FLEXIBLE_SPACE,
      foregroundColor: UIConsts.APPBAR_TEXT_COLOR,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(UIConsts.APPBAR_TOOLBAR_HEIGHT + (bottom?.preferredSize.height ?? 0.0));

}