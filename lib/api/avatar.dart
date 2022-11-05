import 'dart:io';

import '../const/secret_config.dart';
import '../util/network.dart';
import '../util/log.dart';

String _host = SecretConfig.get('API_HOST');

class AvatarAPI {
  /// 基础的增删改查
  static create(File file) async {
    String url = "$_host/avatar/create";
    var result = await NetworkUtil.post(url, {
      'file': file,
    }, [], 'file');
    if (result == false) {
      log('【创建失败】');
    }
    return result;
  }
}
