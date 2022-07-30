import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import '../const/secret_config.dart';
import 'log.dart';


class LBS {
  // 批量逆地理，多于20个，自动按20个拆开并发请求
  static Future<List> batchRegeo(List<Map> lonlats) async {
    List groups = [];
    int len = lonlats.length;
    int groupCount = (len / 20).ceil();
    for (int i = 0; i < groupCount; i++) {
      groups.add(lonlats.sublist(i * 20, min((i + 1) * 20, len)));
    }
    log("收到$len个，拆成$groupCount组");

    List<Future> tasks = groups.map((lonlats) async {
      String location = lonlats.map((lonlat) => "${lonlat['lon']},${lonlat['lat']}").join('|');
      var res;
      try {
        var response = await Dio().get('https://restapi.amap.com/v3/geocode/regeo?parameters',
          queryParameters: {
            'key': SecretConfig.get('AMAP_LBS_KEY'),
            'location': location,
            'batch': true,
          },
        );
        // log(response);
        res = jsonDecode(response.toString());
      } catch (e) {
        log(e);
      }
      if (int.parse(res['status']) == 1) {
        // 批处理字段不一样，多个s - -
        return res['regeocodes'];
      }
      return [];
    }).toList();
    List results = await Future.wait(tasks);
    // 打平
    List address = [];
    results.forEach((result) {
      address.addAll(result);
    });
    return address;
  }

  // 逆地理 https://developer.amap.com/api/webservice/guide/api/georegeo#regeo
  static Future<Map> regeo(double lon, double lat) async {
    var res;
    try {
      var response = await Dio().get('https://restapi.amap.com/v3/geocode/regeo?parameters',
        queryParameters: {
          'key': SecretConfig.get('AMAP_LBS_KEY'),
          // 'location': '116.401162,40.027265',
          'location': '$lon,$lat',
        },
      );
      // log(response);
      res = jsonDecode(response.toString());
    } catch (e) {
      log(e);
    }
    if (int.parse(res['status']) == 1) {
      return res['regeocode'];
    }

    return {};
  }
}
