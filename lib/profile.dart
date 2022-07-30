import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_avatar/flutter_advanced_avatar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'api/record.dart';
import 'util/toast.dart';
import 'util/account.dart';
import 'util/dialog.dart';
import 'api/account.dart';
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
    log('settings');
  }

  _onAboutPressed() {
    Navigator.of(context).pop();
    Navigator.pushNamed(context, '/about');
  }

  _onLogoutPressed() async {
    await AccountAPI.logout();
    // 无论服务成功失败都删除本地token
    AccountUtil.removeToken().then((_) {
      setState(() {
        isLoggedIn = AccountUtil.isLoggedIn();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Divider div = const Divider(height: 1, color: Colors.black12, indent: 20, endIndent: 20);
    Widget avatar = AdvancedAvatar(
      size: 80,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(43, 43, 43, 0.45),
        borderRadius: BorderRadius.circular(40),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 40,
      ),
    );

    if (isLoggedIn) {
      String nickname = AccountUtil.getNickname();
      avatar = AdvancedAvatar(
        name: nickname.isNotEmpty ? nickname.split('').join(' ') : 'H i',
        size: 80,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(43, 43, 43, 0.45),
          borderRadius: BorderRadius.circular(40),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("我的"),
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
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 40, 0, 20),
                  child: avatar,
                ),
                Container(
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: isLoggedIn ?
                    const Text(
                      '见到你很高兴!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ) : ElevatedButton(
                      onPressed: _onLoginPressed,
                      child: const Text(
                        '登录/注册',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        )
                      ),
                    ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.history_rounded),
            title: Text('历史记录'),
            onTap: _onHistoryPressed,
          ),
          div,
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('设置'),
            onTap: _onSettingsPressed,
          ),
          div,
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            onTap: _onAboutPressed,
          ),
          isLoggedIn ? ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: _onLogoutPressed,
          ) : const SizedBox(),
        ],
      ),
    );
  }
}