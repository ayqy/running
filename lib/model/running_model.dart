import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:running/const/sport_type.dart';

import '../const/running_status.dart';

/// 业务数据模型，交互状态不放在这里
class RunningModel extends ChangeNotifier {
  // 主状态
  RunningStatus status = RunningStatus.idle;
  setStatus(RunningStatus s) {
    status = s;
    notifyListeners();
  }

  // 运动类型
  Map sportType = SportType.running;
  void setSportType(type) {
    sportType = type;
    notifyListeners();
  }

  // 跑步开始时间，毫秒时间戳
  int _startTime = 0;
  void setStartTime(ts) {
    _startTime = ts;
  }
  int getStartTime() {
    return _startTime;
  }

  // 跑步结束时间，毫秒时间戳
  int _endTime = 0;
  void setEndTime(ts) {
    _endTime = ts;
  }
  int getEndTime() {
    return _endTime;
  }

  // 起点位置
  Map<String, Object>? _startPosition;
  void setStartPosition(location) {
    _startPosition = location;
  }
  Map<String, Object>? getStartPosition() {
    return _startPosition;
  }

  // 终点位置
  Map<String, Object>? _endPosition;
  void setEndPosition(location) {
    _endPosition = location;
  }
  Map<String, Object>? getEndPosition() {
    return _endPosition;
  }

  // 总距离，米
  double _distance = 0.0;
  // 数米
  double countDistance(double m) {
    _distance += m;
    notifyListeners();
    return _distance;
  }
  void setDistance(m) {
    _distance = m;
  }
  double getDistance() {
    return _distance;
  }

  // 总时长，秒
  int _duration = 0;
  // 数秒
  int countDuration() {
    _duration++;
    notifyListeners();
    return _duration;
  }
  void setDuration(s) {
    _duration = s;
  }
  int getDuration() {
    return _duration;
  }

  final List<int> _kmDurations = [];
  void recordKMDurations(value) {
    _kmDurations.add(value);
    notifyListeners();
  }
  void clearKMDurations() {
    _kmDurations.clear();
    notifyListeners();
  }
  List<int> getKMDurations() {
    return _kmDurations;
  }

  Map toMap() {
    return {
      'sportType': sportType['value'],
      'startTime': getStartTime(),
      'endTime': getEndTime(),
      'startPosition': getStartPosition(),
      'endPosition': getEndPosition(),
      'distance': getDistance(),
      'duration': getDuration(),
      'kmDurations': getKMDurations(),
    };
  }

  static RunningModel load(Map data) {
    RunningModel model = RunningModel();
    model.setSportType(SportType.fromValue(data['sportType']));
    model.setStartTime(data['startTime']);
    model.setEndTime(data['endTime']);
    model.setStartPosition(data['startPosition']);
    model.setEndPosition(data['endPosition']);
    model.setDistance(data['distance']);
    model.setDuration(data['duration']);
    // 一定是完成态
    model.status = RunningStatus.done;

    return model;
  }

  activate() {
    notifyListeners();
  }

  reset() {
    status = RunningStatus.idle;
    setSportType(SportType.running);
    setStartTime(0);
    setEndTime(0);
    setStartPosition(null);
    setEndPosition(null);
    setDistance(0.0);
    setDuration(0);
    clearKMDurations();
  }
}
