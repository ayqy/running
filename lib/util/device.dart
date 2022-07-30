import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import '../const/storage_key.dart';
import '../util/storage.dart';
import '../util/log.dart';

String? _diu;
class DeviceUtil {
  static init() async {
    _diu = await _getDeviceId();
  }

  static String getId() {
    if (_diu != null) {
      return _diu!;
    }
    throw AssertionError('无法获取diu');
  }

  static _getDeviceId() async {
    // 先从storage里取一把
    String deviceId = await Storage.get(deviceIdKey);
    if (deviceId.isNotEmpty) {
      _diu = deviceId;
      return _diu;
    }

    // 没有才从设备获取
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _diu = iosInfo.identifierForVendor;
    }
    else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _diu = androidInfo.androidId;
    }
    else {
      throw AssertionError('Unsupported platform');
    }
    log("diu=$_diu");
    // 取到设备id，存入localStorage防止它会（iOS是keychain）
    await Storage.set(deviceIdKey, _diu);

    return _diu;
  }
}
