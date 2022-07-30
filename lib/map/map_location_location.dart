import 'dart:async';
import 'dart:math';

import 'package:location/location.dart';
import '../util/map.dart';

class MapLocationLocation {
  static bool _isPermissionGranted = false;
  static Location _locationPlugin = Location();
  static bool _serviceEnabled = false;
  static PermissionStatus _permissionGranted = PermissionStatus.denied;
  static Map<String, Object>? _locationResult;
  static Function? _onLocationChanged;
  static Function? _onReady;
  static bool _randomOffset = false;
  static final List<Map<String, Object>> _locationTrack = [];

  static void enableRandomOffset(enabled) {
    MapLocationLocation._randomOffset = enabled;
  }

  // 检查定位相关权限
  static Future<void> checkPermission() async {
    _permissionGranted = await _locationPlugin.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationPlugin.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        throw AssertionError('定位权限获取失败');
      }
    }
    MapLocationLocation._isPermissionGranted = true;
  }

  static void _permissionGuard() {
    if (MapLocationLocation._isPermissionGranted != true) {
      throw AssertionError('缺少定位权限，定位模块无法工作');
    }
  }

  static void init({ debug }) async {
    _permissionGuard();
    // 允许后台定位
    _locationPlugin.enableBackgroundMode(enable: true);
    // 启动定位服务
    _serviceEnabled = await _locationPlugin.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationPlugin.requestService();
      if (!_serviceEnabled) {
        throw AssertionError('定位服务启动失败');
      }
    }

    onLocationChange();
    _startLoation();
  }

  static Map<String, Object>? getLocation() {
    _permissionGuard();
    return MapLocationLocation._locationResult;
  }

  static List<Map<String, Object>>? getLocationTrack() {
    _permissionGuard();
    return MapLocationLocation._locationTrack;
  }

  static void _startLoation() async {
    _permissionGuard();
    LocationData data = await _locationPlugin.getLocation();
    _locationResult = _convertLocationData(data);
  }

  static void startLocation(onLocationChanged) {
    _permissionGuard();
    // 清掉上次轨迹
    _locationTrack.clear();
    // 先stop一把
    stopLocation();
    MapLocationLocation._onLocationChanged = onLocationChanged;
    _startLoation();
  }

  static void stopLocation() {
    MapLocationLocation._onLocationChanged = null;
  }

  static void dispose() {
    //...
  }

  static void onReady(readyCallback) {
    // 有定位结果立即回调
    if (_locationResult != null) {
      readyCallback(_locationResult);
    }
    // 否则记下等着，拿到第一次定位结果后再回调
    else {
      _onReady = readyCallback;
    }
  }

  static Map<String, Object> _convertLocationData(LocationData data) {
    Map<String, Object> event = <String, Object>{};
    // 转换结构，以AMap的为准
    // 标准经纬度需要转换加偏移
    List<double> latlng = MapUtil.convertGPSToAMapLatLng(data.latitude!, data.longitude!);
    event['latitude'] = latlng[0];
    event['longitude'] = latlng[1];
    event['accuracy'] = data.accuracy as Object;
    event['altitude'] = data.altitude as Object;
    event['speed'] = data.speed as Object;
    event['speedAccuracy'] = data.speedAccuracy as Object;
    event['heading'] = data.heading as Object;
    event['time'] = data.time as Object;
    event['isMock'] = data.isMock as Object;
    return event;
  }

  static void onLocationChange() {
    _locationPlugin.onLocationChanged.listen((LocationData currentLocation) {
      Map<String, Object> event = _convertLocationData(currentLocation);
      // if debug 随机飘点
      if (MapLocationLocation._randomOffset) {
        double factor = 0.001;
        // double factor = 0.01;
        double randomDeltaLat = Random().nextDouble() * factor;
        double randomDeltaLng = Random().nextDouble() * factor;
        event['latitude'] = (event['latitude'] as double) + randomDeltaLat;
        event['longitude'] = (event['longitude'] as double) + randomDeltaLng;
        // 根据delta随机speed
        event['speed'] = (randomDeltaLat + randomDeltaLng) / 4 * 10000;
      }
      // 更新当前定位
      _locationResult = event;
      // 记录轨迹
      _locationTrack.add(_locationResult!);
      if (MapLocationLocation._onLocationChanged != null) {
        MapLocationLocation._onLocationChanged!(_locationResult);
      }
      // 回调第一次定位
      if (_onReady != null) {
        _onReady!(_locationResult);
        _onReady = null;
      }
    });
  }
}

