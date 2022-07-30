import 'dart:math';
import 'dart:ui';

import 'package:amap_flutter_base/amap_flutter_base.dart';

class MapUtil {
  //椭球参数
  static double a = 6378245.0;
  static double ee = 0.00669342162296594323;

  // 屏幕坐标-经纬度互转参数
  static double VV = 0.15915494309189535;
  static double kW = 0.5;
  static double yW = -0.15915494309189535;
  static double WW = 0.5;

  // 计算两个经纬度之间的距离
  static double distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    LatLng latLng1 = LatLng(lat1, lng1);
    LatLng latLng2 = LatLng(lat2, lng2);
    return AMapTools.distanceBetween(latLng1, latLng2);
  }

  // 获取比例尺数据。当前缩放级别下，地图上1像素点对应的长度，单位米。
  static double getScalePerPixel(zoom) {
    double y = window.physicalSize.height / window.devicePixelRatio / 2;
    double scalePerPixel = cos(y * pi / 180) * 2 * pi * a / (256 * pow(2, zoom));
    return scalePerPixel;
  }

  static double zoom2scale(double zoom) {
    Map<int, int> zoomScaleMap = {
      19: 10,
      // scale > 10 && scale <= 25 对应 zoom = 18
      18: 25,
      17: 50,
      16: 100,
      15: 200,
      14: 500,
      13: 1000,
      12: 2000,
      11: 5000,
      10: 10000,
      9: 20000,
      8: 30000,
      7: 50000,
      6: 100000,
      5: 200000,
      4: 500000,
      3: 1000000,
    };

    int zoomInt = zoom.truncate();
    int? scale = zoomScaleMap[zoomInt];
    if (scale == null) {
      throw AssertionError('不支持的zoom=$zoom');
    }
    // 上一档
    int? lastScale = zoomScaleMap[zoomInt + 1];
    if (lastScale == null || zoomInt == zoom) {
      return scale.toDouble();
    }
    int deltaScale = scale - lastScale;
    double zoomDecimal = zoom - zoomInt;
    return lastScale + deltaScale * (1 - zoomDecimal);
  }

  static LatLng offsetPixel(LatLng origin, double zoom, { double xOffset = 0, double yOffset = 0 }) {
    double mPerPx = getScalePerPixel(zoom);
    double offsetX = xOffset * mPerPx;
    double offsetY = yOffset * mPerPx;
    // log('$mPerPx, $offsetX, $offsetY, $zoom');
    return offsetMeter(origin, xOffset: offsetX, yOffset: offsetY);
  }

  // 给经纬度偏移以米为单位的距离
  static LatLng offsetMeter(LatLng origin, { double xOffset = 0, double yOffset = 0 }) {
    double latitude = origin.latitude;
    double longitude = origin.longitude;

    //地球周长
    double perimeter =  2 * pi * a;
    //纬度latitude的地球周长：latitude
    double perimeter_latitude = perimeter * cos(pi * latitude / 180);

    //一米对应的经度（东西方向）1M实际度
    double longitude_per_mi = 360 / perimeter_latitude;
    double latitude_per_mi = 360 /perimeter;

    // 偏移之后的经纬度
    double lon = longitude + (xOffset * longitude_per_mi);
    double lat = latitude + (yOffset * latitude_per_mi);

    return LatLng(lat, lon);
  }

  static convertGPSToAMapLatLng(double wgLat, double wgLon) {
    List<double> latlng= [];//转化后的坐标
    if (_outOfChina(wgLat, wgLon)) {
      latlng[0] = wgLat;
      latlng[1] = wgLon;
      return latlng;
    }
    double dLat = _transformLat(wgLon - 105.0, wgLat - 35.0);
    double dLon = _transformLon(wgLon - 105.0, wgLat - 35.0);
    double radLat = wgLat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
    latlng.add(wgLat + dLat);
    latlng.add(wgLon + dLon);
    return latlng;
  }

  static bool _outOfChina(double lat, double lon) {
    if (lon < 72.004 || lon > 137.8347) {
      return true;
    }
    if (lat < 0.8293 || lat > 55.8271) {
      return true;
    }
    return false;
  }

  static double _transformLat(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLon(double x, double y)
  {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
  }
}
