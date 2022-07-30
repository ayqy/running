import 'package:flutter/material.dart';
import 'package:running/const/running_status.dart';

class SportType {
  // static Map walk = {
  //   'label': '健走',
  //   'icon': Icons.directions_walk_sharp,
  //   'value': 0,
  // };

  static Map running = {
  'label': '跑步',
  'icon': Icons.directions_run_sharp,
  'value': 1,
  };

  static Map ride = {
    'label': '骑行',
    'icon': Icons.directions_bike_sharp,
    'value': 2,
  };

  // 【注意】values需要同步维护
  static List<int> values() {
    return [
      // SportType.walk['value'],
      SportType.running['value'],
      SportType.ride['value'],
    ];
  }

  static Map fromValue(value) {
    Map type;
    switch(value) {
      case 2:
        type = SportType.ride;
        break;
      default:
        type = SportType.running;
        break;
    }
    return type;
  }
}
