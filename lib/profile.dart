import 'package:flutter/material.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'api/record.dart';
import 'const/ui.dart';
import 'util/toast.dart';
import 'util/account.dart';
import 'util/dialog.dart';
import 'util/log.dart';


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
          MyDialog.confirm(context, '是否将历史记录同步至当前账号？', () async {
            var result = await RecordAPI.own();
            if (result != false) {
              toast('同步成功');
            }
            else {
              toast('同步失败，请检查网络');
            }
          });
        }
      }
    });
  }

  _onAvatarPressed() {
    Navigator.of(context).pop();
    Navigator.pushNamed(context, '/account_settings');
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
    Divider div = const Divider(height: 1, color: Colors.black12, indent: 20, endIndent: 20);
    Widget avatar = CircularProfileAvatar(
      '',
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 40,
      ),
      radius: 40,
      backgroundColor: const Color.fromRGBO(43, 43, 43, 0.45),
      borderWidth: 4,
      borderColor: Colors.white,
      foregroundColor: Colors.white.withOpacity(0.5),
      cacheImage: true,
      imageFit: BoxFit.cover,
    );

    String nickname = '';
    if (isLoggedIn) {
      nickname = AccountUtil.getNickname();
      String avatarUrl = AccountUtil.getAvatarUrl();
      avatar = CircularProfileAvatar(
        avatarUrl,
        radius: 25,
        initialsText: avatarUrl.isEmpty ? Text(
          nickname,
          style: const TextStyle(fontSize: 40, color: Colors.white),
        ) : const Text(''),
        backgroundColor: const Color.fromRGBO(43, 43, 43, 0.45),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: UIConsts.APPBAR_TOOLBAR_HEIGHT,
        title: const Text("我的"),
        flexibleSpace: UIConsts.APPBAR_FLEXIBLE_SPACE,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xfff5f5f5),
              image: isLoggedIn ? const DecorationImage(
                image: AssetImage('images/orange-sky.png'),
                fit: BoxFit.fill,
              ) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isLoggedIn ? InkWell(
                  onTap: _onAvatarPressed,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 40, 0, 20),
                    child: Row(
                      children: [
                        avatar,
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname,
                              style: const TextStyle(
                                color: Color(0xff333333),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: const [
                                Text(
                                  '账号与资料',
                                  style: TextStyle(
                                    color: Color(0xff999999),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Color(0xff999999),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ) : Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(0, 30, 0, 20),
                  child: avatar,
                ),
                Container(
                  height: 48,
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: isLoggedIn ? const Text(
                    '见到你很高兴!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ) : ElevatedButton(
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all<Size>(const Size.fromHeight(40)),
                    ),
                    onPressed: _onLoginPressed,
                    child: const Text(
                      '登录/注册',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('历史记录'),
            onTap: _onHistoryPressed,
          ),
          div,
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: _onSettingsPressed,
          ),
          div,
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            onTap: _onAboutPressed,
          ),
        ],
      ),
    );
  }
}