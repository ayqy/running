import 'dart:convert';

import 'package:flutter/services.dart';

import '../util/log.dart';

Map _data = {};
class SecretConfig {
  static Future<void> load() async {
    try {
      final String response = await rootBundle.loadString('production/production.json');
      _data = await jsonDecode(response);
    } catch(error) {
      log(error);
      log("配置文件有误，将无法使用部分功能");
    }
  }

  static String get(key) {
    var value = _data[key];
    log("$key=$value");
    if (value == null) {
      throw AssertionError("常量获取失败 $key");
    }
    return value;
  }
}
