import 'dart:convert';

import 'package:running/util/network.dart';

import '../const/secret_config.dart';
import '../const/storage_key.dart';
import '../util/storage.dart';
import '../util/log.dart';

String _host = SecretConfig.get('API_HOST');

class RecordAPI {


  /// 在增删改查基础上实现的业务接口
  static syncRecords() {
    Storage.get(localKey).then((String value) async {
      List records = [];
      if (value.isNotEmpty) {
        try {
          records = jsonDecode(value);
        } catch(error) {
          log(error);
          // 历史记录坏了
          throw AssertionError('历史记录格式不正确');
        }
      }
      List recordsToUpload = records.where((record) => record['uploaded'] == null).toList();
      log('${recordsToUpload.length} 条数据待同步');
      if (recordsToUpload.isNotEmpty) {
        var result = await uploadRecords(recordsToUpload);
        if (result == false) {
          log('【同步失败】');
        }
        else {
          // 标记这些记录已经落库了
          recordsToUpload.forEach((record) {
            record['uploaded'] = 1;
          });
          // 写回本地
          // 这里有badcase，中间新增的本地记录会丢，暂不处理
          Storage.set(localKey, jsonEncode(records)).then((_) {
            log('数据同步完成');
          });
          // todo 删掉本地记录
        }
      }
    });
  }
  static uploadRecords(List records) {
    List data = records.map((record) {
      Map item = {};
      item.addAll(record);
      item['startPosition'] = jsonEncode(record['startPosition']);
      item['endPosition'] = jsonEncode(record['endPosition']);
      return item;
    }).toList();
    return create(data);
  }
  static own({checkOnly = false}) async {
    String url = "$_host/records/own";
    var result = await NetworkUtil.post(url, { "checkOnly": checkOnly });
    if (result == false) {
      log(checkOnly ? '【无需同步】' : '【关联失败】');
    }
    return result;
  }
  static sum() async {
    String url = "$_host/records/sum";
    var result = await NetworkUtil.post(url);
    if (result == false) {
      log('【统计失败】');
    }
    return result;
  }

  /// 基础的增删改查
  static create(data) async {
    String url = "$_host/records/create";
    var records = data;
    if (data is! List) {
      records = [data];
    }
    var result = await NetworkUtil.post(url, { 'records': records });
    if (result == false) {
      log('【创建失败】');
    }
    return result;
  }
  static remove(id) async {
    String url = "$_host/records/remove";
    var result = await NetworkUtil.post(url, { 'id': id });
    if (result == false) {
      log('【删除失败】');
    }
    return result;
  }
  static update(id, data) async {
    String url = "$_host/records/update";
    Map params = { 'id': id };
    params.addAll(data);
    var result = await NetworkUtil.post(url, params);
    if (result == false) {
      log('【更新失败】');
    }
    return result;
  }
  static query({startIndex, pageSize = 10, Map? conditions}) async {
    String url = "$_host/records/query";
    if (conditions == null) {
      conditions = {};
    }
    Map data = {};
    data.addAll(conditions);
    if (startIndex != null) {
      data['startIndex'] = startIndex;
    }
    data['pageSize'] = pageSize;
    var result = await NetworkUtil.post(url, data);
    if (result == false) {
      log('【查询失败】');
    }
    return result;
  }
}
