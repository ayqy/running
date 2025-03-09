import 'dart:convert';

import '../api/account.dart';
import '../const/storage_key.dart';
import 'storage.dart';
import 'log.dart';

String? _uid;
String? _token;
Map? _userInfo;
// 这个留作记住账号用，不清空
String? _username;
class AccountUtil {
  static final List<Function> _listeners = [];

  static init() async {
    Map authInfo = await Storage.get(authKey).then((String value) {
      if (value.isNotEmpty) {
        return jsonDecode(value);
      }
      return {};
    });
    if (authInfo['uid'] != null) {
      _uid = authInfo['uid'];
    }
    if (authInfo['token'] != null) {
      _token = authInfo['token'];
    }
    if (_uid == null || _token == null) {
      // 未登录从本地缓存取
      _username = await Storage.get(usernameKey);
      return;
    }
    // 先加载本地缓存nickname、username等信息
    try {
      String userInfoString = await Storage.get(userInfoKey);
      _userInfo = jsonDecode(userInfoString);
    } catch(error) {
      log(error);
    }
    // 回调初始账号信息
    _fireChangeListeners();
    // 再从服务拉取最新的用户信息
    AccountUtil.fetch();
  }

  static _fireChangeListeners() {
    for (var listener in _listeners) {
      listener(_userInfo);
    }
  }

  static onChange(Function callback) {
    _listeners.add(callback);
  }

  static offChange(Function callback) {
    if (_listeners.contains(callback)) {
      _listeners.remove(callback);
    }
  }

  static fetch() async {
    var result = await AccountAPI.auth();
    if (result == false) {
      // 登录状态失效，删除本地token
      await AccountUtil.removeToken();
    }
    else {
      // 登录了从服务返回取
      cache(result);
    }
  }

  static cache(loginRes) {
    _userInfo = loginRes;
    _username = _userInfo?['username'];
    // 以下两个字段，登录接口有返回，校验接口不返回
    if (_userInfo?['uid'] != null) {
      _uid = _userInfo?['uid'];
    }
    if (_userInfo?['token'] != null) {
      _token = _userInfo?['token'];
    }
    Storage.set(usernameKey, _username);
    Storage.set(userInfoKey, jsonEncode(_userInfo));
    // 回调更新的账号信息
    _fireChangeListeners();
  }

  static removeToken() async {
    await Storage.remove(authKey).then((_) {
      _uid = null;
      _token = null;
      _userInfo = null;
    });
    // 回调退登的账号信息
    _fireChangeListeners();
  }

  static bool isLoggedIn() {
    return (_uid?.isNotEmpty ?? false) && (_token?.isNotEmpty ?? false);
  }

  static getUid() {
    return _uid;
  }

  static getToken() {
    return _token;
  }

  static getNickname() {
    return _userInfo?['nickname'] ?? '';
  }

  static getAvatarUrl() {
    return _userInfo?['avatarUrl'] ?? '';
  }

  static getUsername([maybeLogout = false]) {
    if (maybeLogout) {
      return _username ?? '';
    }
    return _userInfo?['username'] ?? '';
  }
}
