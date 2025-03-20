import 'package:flutter/material.dart';
import 'package:running/widget/custom_app_bar.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'api/record.dart';
import 'const/ui.dart';
import 'util/toast.dart';
import 'util/account.dart';
import 'util/dialog.dart';
import 'util/log.dart';
import 'const/theme.dart';


class Profile extends StatefulWidget {
  const Profile({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ProfileState();
  }
}

class _ProfileState extends State<Profile> {
  bool isLoggedIn = AccountUtil.isLoggedIn();

  _onLoginPressed() {
    if (isLoggedIn) {
      Navigator.of(context).pop();
      Navigator.pushNamed(context, '/account_settings');
    } else {
      Navigator.pushNamed(context, '/login').then((_) async {
        bool lastIsLoggedIn = isLoggedIn;
        // 从登录页回来重新获取登录状态
        bool isLoggedInNow = AccountUtil.isLoggedIn();
        setState(() {
          isLoggedIn = isLoggedInNow;
        });
        if (isLoggedInNow != lastIsLoggedIn && isLoggedInNow) {
          // 从未登录变为登录
          // 检查是否有设备数据需要同步到该账号下
          var result = await RecordAPI.own(checkOnly: true);
          if (result == true) {
            if (!mounted) return;
            MyDialog.confirm(context, '是否将历史记录同步至当前账号？', (close) async {
              var result = await RecordAPI.own();
              if (result != false) {
                toast('同步成功');
              }
              else {
                toast('同步失败，请检查网络');
              }
              close();
            });
          }
        }
      });
    }
  }

  _onAvatarPressed() {
    Navigator.of(context).pop();
    if (isLoggedIn) {
      Navigator.pushNamed(context, '/account_settings');
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }

  _onHistoryPressed() {
    if (!AccountUtil.isLoggedIn()) {
      EasyLoading.showInfo('登录后即可查看');
    }
    else {
      Navigator.of(context).pop();
      Navigator.pushNamed(context, '/history');
    }
  }

  _onAchievementsPressed() {
    if (!AccountUtil.isLoggedIn()) {
      EasyLoading.showInfo('登录后即可查看');
    }
    else {
      Navigator.of(context).pop();
      Navigator.pushNamed(context, '/achievements');
    }
  }

  _onSettingsPressed() {
    Navigator.of(context).pop();
    Navigator.pushNamed(context, '/settings');
  }

  _onAboutPressed() {
    Navigator.of(context).pop();
    Navigator.pushNamed(context, '/about');
  }

  @override
  Widget build(BuildContext context) {
    Divider div = Divider(height: 1, color: ThemeColors.dividerColor, indent: 20, endIndent: 20);
    Widget avatar;
    
    if (isLoggedIn && AccountUtil.getAvatarUrl().isNotEmpty) {
      // Use user's avatar if logged in and avatar URL exists
      avatar = CircularProfileAvatar(
        AccountUtil.getAvatarUrl(),
        radius: 40,
        backgroundColor: ThemeColors.cardColor.withOpacity(0.45),
        borderWidth: 4,
        borderColor: ThemeColors.selectedColor,
        foregroundColor: ThemeColors.valueTextColor.withOpacity(0.5),
        cacheImage: true,
        imageFit: BoxFit.cover,
        errorWidget: (context, url, error) => Icon(
          Icons.person_rounded,
          color: ThemeColors.valueTextColor,
          size: 40,
        ),
      );
    } else {
      // Default avatar for not logged in users
      avatar = CircularProfileAvatar(
        '',
        child: Icon(
          Icons.person_rounded,
          color: ThemeColors.valueTextColor,
          size: 40,
        ),
        radius: 40,
        backgroundColor: ThemeColors.cardColor.withOpacity(0.45),
        borderWidth: 4,
        borderColor: ThemeColors.selectedColor,
        foregroundColor: ThemeColors.valueTextColor.withOpacity(0.5),
        cacheImage: true,
        imageFit: BoxFit.cover,
      );
    }

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ThemeColors.profileHeaderGradientColors,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _onAvatarPressed,
                      child: avatar,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: GestureDetector(
                        onTap: _onLoginPressed,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoggedIn ? AccountUtil.getNickname() : '点击登录',
                              style: TextStyle(fontSize: 24, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLoggedIn ? AccountUtil.getUsername() : '登录后可同步数据',
                              style: TextStyle(color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.history_rounded, color: ThemeColors.selectedColor),
            title: Text('历史记录', style: TextStyle(color: ThemeColors.valueTextColor)),
            onTap: _onHistoryPressed,
          ),
          div,
          ListTile(
            leading: Icon(Icons.emoji_events_rounded, color: ThemeColors.selectedColor),
            title: Text('运动成就', style: TextStyle(color: ThemeColors.valueTextColor)),
            onTap: _onAchievementsPressed,
          ),
          div,
          ListTile(
            leading: Icon(Icons.settings, color: ThemeColors.selectedColor),
            title: Text('设置', style: TextStyle(color: ThemeColors.valueTextColor)),
            onTap: _onSettingsPressed,
          ),
          div,
          ListTile(
            leading: Icon(Icons.info_outline, color: ThemeColors.selectedColor),
            title: Text('关于', style: TextStyle(color: ThemeColors.valueTextColor)),
            onTap: _onAboutPressed,
          ),
        ],
      ),
    );
  }
}