import 'dart:convert';

import '../const/secret_config.dart';
import '../util/account.dart';
import '../util/network.dart';
import '../util/log.dart';
import '../const/storage_key.dart';
import '../util/storage.dart';

String _host = SecretConfig.get('API_HOST');

class AccountAPI {
  /// 在增删改查基础上实现的业务接口
  static signup(data) async {
    var result = await create(data);
    if (result == false) {
      log('【注册失败】');
    }
    return result;
  }
  static login(data) async {
    String url = "$_host/accounts/login";
    var result = await NetworkUtil.post(url, data);
    if (result == false) {
      log('【登录失败】');
    }
    else if (result['uid'] != null && result['token'] != null) {
      // 保存好token
      await Storage.set(authKey, jsonEncode(result)).then((_) {
        return AccountUtil.cache(result);
      });
    }
    return result;
  }
  static auth() async {
    String url = "$_host/accounts/auth";
    var result = await NetworkUtil.post(url);
    if (result == false) {
      log('【登录状态验证失败】');
    }
    return result;
  }
  static logout() async {
    String url = "$_host/accounts/logout";
    var result = await NetworkUtil.post(url);
    if (result == false) {
      log('【退登失败】');
    }
    return result;
  }

  /// 基础的增删改查
  static create(data) async {
    String url = "$_host/accounts/create";
    var result = await NetworkUtil.post(url, data);
    if (result == false) {
      log('【创建失败】');
    }
    return result;
  }
  static remove() async {
    String url = "$_host/accounts/remove";
    var result = await NetworkUtil.post(url);
    if (result == false) {
      log('【删除失败】');
    }
    return result;
  }
  static update(data) async {
    String url = "$_host/accounts/update";
    var result = await NetworkUtil.post(url, data);
    if (result == false) {
      log('【更新失败】');
    }
    return result;
  }
  static query({Map? conditions}) async {
    String url = "$_host/accounts/query";
    if (conditions == null) {
      conditions = {};
    }
    Map data = {};
    data.addAll(conditions);
    var result = await NetworkUtil.post(url, data);
    if (result == false) {
      log('【查询失败】');
    }
    return result;
  }
}
