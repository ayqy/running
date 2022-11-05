import 'log.dart';

class Formatter {
  /// m 转 km
  static String formatDistance(m) {
    return (((m / 1000) * 10).truncate() / 10).toStringAsFixed(1);
  }

  /// s 转 hh:mm:ss 或 h
  static String formatDuration(s, [h = false]) {
    if (h) {
      String h = (s / 60 / 60).toStringAsFixed(1);
      return h;
    }

    String hh = ((s / 60 / 60).truncate()).toString().padLeft(2, '0');
    String mm = ((s / 60).truncate() % 60).toString().padLeft(2, '0');
    String ss = (s % 60).toString().padLeft(2, '0');
    return "$hh:$mm:$ss";
  }

  /// ms 转 xx分xx秒
  static String formatDurationAsTTSString(ms) {
    int totalSeconds = (ms / 1000).truncate();
    int s = totalSeconds % 60;
    int m = (totalSeconds / 60).truncate();
    return m > 0 ? "$m分$s秒" : "$s秒";
  }

  /// m/s 转 min/km（默认），或者km/（kmph=true）
  static String formatSpeed(double mps, [bool kmph = false]) {
    if (mps.isNaN) {
      return "0'00\"";
    }
    if (kmph) {
      return (mps * 3.6).toStringAsFixed(1);
    }

    double mpm = mps * 60;
    double min = 1000 / mpm;
    // 速度太慢，返回>60，避免超长
    if (min > 60) {
      return ">60'";
    }
    String m = min.truncate().toString();
    String s = (min * 60 % 60).round().toString().padLeft(2, '0');
    return "$m'$s\"";
  }

  /// kcal
  static String formatKcal(kcal) {
    return kcal.round().toString();
  }

  /// 格式化逆地理结果
  static String formatAddress(Map regeocode, [defaultAddress = '']) {
    if (regeocode.isEmpty) {
      return defaultAddress;
    }

    String fullAddress = regeocode['formatted_address'];
    String province = regeocode['addressComponent']['province'];
    String district = regeocode['addressComponent']['district'];
    String township = regeocode['addressComponent']['township'];
    // 太长了，干掉省市区街道
    String stripped = fullAddress.replaceFirst(province, '').replaceFirst(district, '').replaceFirst(township, '');
    return stripped;
  }

  /// 跑步热量（kcal）＝体重（kg）×运动时间（小时）×指数K
  /// 指数K＝30÷速度（分钟/400米）
  static double getKcal(s, mps, [kg = 60, isRunning = true]) {
    // 不是跑步就根据速度简单算
    if (!isRunning) {
      double kmph = mps * 3.6;
      int factor;
      if (kmph <= 9) {
        factor = 245;
      }
      else if (kmph <= 16) {
        factor = 415;
      }
      else if (kmph <= 21) {
        factor = 655;
      }
      else {
        factor = 1005;
      }
      double h = s / 60 / 60;
      return factor * h;
    }

    double h = s / 60 / 60;
    double mp400m = 400 / mps / 60;
    double K = 30 / mp400m;
    double kcal = kg * h * K;
    return kcal;
  }
}
