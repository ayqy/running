import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'toast.dart';
import 'account.dart';
import 'device.dart';
import 'env.dart';
import 'log.dart';


enum NetworkStatus {
  mobile,
  wifi,
  offline,
}

class NetworkUtil {
  static getNetworkStatus() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return NetworkStatus.mobile;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return NetworkStatus.wifi;
    }

    return NetworkStatus.offline;
  }

  static getUrl(String url) {
    Uri uri = Uri.parse(url);
    List pathSegments = uri.pathSegments.toList();
    String targetEntity = pathSegments[0];
    if (!EnvUtil.isProduction()) {
      pathSegments[0] = "${targetEntity}_test";
      uri = uri.replace(
        path: pathSegments.join('/'),
      );
    }

    return uri.toString();
  }

  static Future<Map<String, Object>> getCommonParams() async {
    // 公参
    Map<String, Object> params = {
      'diu': DeviceUtil.getId(),
    };
    if (AccountUtil.isLoggedIn()) {
      params['uid'] = AccountUtil.getUid();
    }
    return params;
  }

  static post(url, [params]) async {
    // 检查网络状况，是否断网
    bool isOffline = NetworkUtil.getNetworkStatus() == NetworkStatus.offline;
    if (isOffline) {
      toast('网络状况不佳，请稍后再试～');
      return false;
    }
    Map reqParams = {};
    reqParams.addAll(params ?? {});
    // 带上公参
    Map commonParams = await NetworkUtil.getCommonParams();
    reqParams.addAll(commonParams);
    log('>>>');
    log(NetworkUtil.getUrl(url));
    log(reqParams);
    // 发请求
    var res;
    try {
      Options options = Options();
      if (AccountUtil.isLoggedIn()) {
        options.headers = {
          'Authorization': "Bearer ${AccountUtil.getToken()}",
        };
      }
      log('===');
      log(options.headers);
      var response = await Dio().post(
        NetworkUtil.getUrl(url),
        data: reqParams,
        options: options,
      );
      // log(response);
      res = jsonDecode(response.toString());
    } catch (e) {
      log(e);
    }
    log('<<<');
    log(res);
    if (res['code'] == 1) {
      return res['data'];
    }

    return false;
  }
}
