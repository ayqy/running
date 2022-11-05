import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:running/util/crypto.dart';
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

  static sign(Map params, List<String> keys, [bool stringify = false]) {
    Map<String, dynamic> signed = Map.from(params);
    keys.forEach((key) {
      String value = params[key];
      String encrypted = encrypt(value);
      if (decrypt(encrypted) != value) {
        throw AssertionError('对称加解密反解不回来');
      }
      signed[key] = encrypted;
    });
    signed['signed_keys'] = stringify ? jsonEncode(keys) : keys;
    return signed;
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

  static post(url, [params, List<String>? signFields, String? fileKey]) async {
    // 检查网络状况，是否断网
    bool isOffline = await NetworkUtil.getNetworkStatus() == NetworkStatus.offline;
    if (isOffline) {
      toast('网络状况不佳，请稍后再试～');
      return false;
    }
    Map reqParams = {};
    reqParams.addAll(params ?? {});
    // 文件上传，转换参数
    bool isFileUploading = fileKey != null && reqParams[fileKey] != null;
    if (isFileUploading) {
      File file = reqParams[fileKey];
      String fileName = file.path.split('/').last;
      reqParams[fileKey] = await MultipartFile.fromFile(file.path, filename: fileName);
    }
    // 带上公参
    Map commonParams = await NetworkUtil.getCommonParams();
    reqParams.addAll(commonParams);
    // 参数鉴权
    signFields = signFields ?? [];
    // 公参默认全部鉴权
    signFields.addAll(commonParams.keys.toList() as List<String>);
    Map<String, dynamic> signedParams = sign(reqParams, signFields, isFileUploading);
    log('>>>');
    log(NetworkUtil.getUrl(url));
    log(signedParams);
    // 发请求
    var res;
    try {
      Options options = Options();
      if (AccountUtil.isLoggedIn()) {
        options.headers = {
          'Authorization': "Bearer ${AccountUtil.getToken()}",
        };
      }
      if (isFileUploading) {
        options.contentType = 'multipart/form-data';
      }
      log('===');
      log(options.headers);
      FormData? formData;
      if (isFileUploading) {
        formData = FormData.fromMap(signedParams);
      }
      var response = await Dio().post(
        NetworkUtil.getUrl(url),
        data: isFileUploading ? formData : signedParams,
        options: options,
      );
      log(response);
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
