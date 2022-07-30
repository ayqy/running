import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';
import 'map_config_amap.dart';

class MapLocationAMap {
  static bool _isPermissionGranted = false;
  static AMapFlutterLocation? _locationPlugin;
  static StreamSubscription<Map<String, Object>>? _locationListener;
  static Map<String, Object>? _locationResult;
  static Function? _onLocationChanged;
  static Function? _onReady;
  static bool _debugMode = false;
  static final List<Map<String, Object>> _locationTrack = [];

  // 检查定位相关权限
  static Future<void> checkPermission() async {
    MapLocationAMap._isPermissionGranted = await _checkPermission();
  }

  static void _permissionGuard() {
    if (MapLocationAMap._isPermissionGranted != true) {
      throw AssertionError('缺少定位权限，定位模块无法工作');
    }
  }

  static void init({ debug }) {
    MapLocationAMap._debugMode = debug;

    _permissionGuard();
    AMapFlutterLocation.setApiKey(MapConfigAMap.amapApiKeys.androidKey ?? '', MapConfigAMap.amapApiKeys.iosKey ?? '');
    if (Platform.isIOS) {
      requestAccuracyAuthorization();
    }
    _locationPlugin = AMapFlutterLocation();
    onLocationChange();
    _startLoation();
  }

  static Map<String, Object>? getLocation() {
    _permissionGuard();
    return MapLocationAMap._locationResult;
  }

  static List<Map<String, Object>>? getLocationTrack() {
    _permissionGuard();
    return MapLocationAMap._locationTrack;
  }

  static void _startLoation() {
    _permissionGuard();
    setLocationOptions();
    _locationPlugin?.startLocation();
  }

  static void startLocation(onLocationChanged) {
    _permissionGuard();
    // 清掉上次轨迹
    _locationTrack.clear();
    // 先stop一把
    stopLocation();
    MapLocationAMap._onLocationChanged = onLocationChanged;
    _startLoation();
  }

  static void stopLocation() {
    _locationPlugin?.stopLocation();
    MapLocationAMap._onLocationChanged = null;
  }

  static void dispose() {
    if (_locationListener != null) {
      _locationListener?.cancel();
      _locationListener = null;
    }
    if (_locationPlugin != null) {
      _locationPlugin?.destroy();
      _locationPlugin = null;
    }
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

  static void onLocationChange() {
    _locationListener = _locationPlugin
        ?.onLocationChanged()
        .listen((Map<String, Object> event) {
      if (event['latitude'] != null && event['longitude'] != null) {
        event['latitude'] = double.parse(event['latitude'].toString());
        event['longitude'] = double.parse(event['longitude'].toString());
        // if debug 随机飘点
        if (MapLocationAMap._debugMode) {
          double randomDeltaLat = Random().nextDouble() * 0.001;
          double randomDeltaLng = Random().nextDouble() * 0.001;
          event['latitude'] = (event['latitude'] as double) + randomDeltaLat;
          event['longitude'] = (event['longitude'] as double) + randomDeltaLng;
        }
        // 更新当前定位
        _locationResult = event;
        // 记录轨迹
        _locationTrack.add(_locationResult!);
        if (MapLocationAMap._onLocationChanged != null) {
          MapLocationAMap._onLocationChanged!(_locationResult);
        }
        // 回调第一次定位
        if (_onReady != null) {
          _onReady!(_locationResult);
          _onReady = null;
        }
      }
    });
  }

  static void setLocationOptions() {
    AMapLocationOption locationOption = AMapLocationOption();
    // 是否单次定位
    locationOption.onceLocation = false;
    // 是否需要逆地理信息
    locationOption.needAddress = false;
    // 逆地理信息语言类型
    locationOption.geoLanguage = GeoLanguage.ZH;
    // iOS14期望定位精度
    locationOption.desiredLocationAccuracyAuthorizationMode = AMapLocationAccuracyAuthorizationMode.ReduceAccuracy;
    // todo iOS 14中定位精度权限由模糊定位升级到精确定位时，需要用到的场景key fullAccuracyPurposeKey 这个key要和plist中的配置一样
    locationOption.fullAccuracyPurposeKey = 'AMapLocationScene';
    // 安卓端连续定位间隔
    locationOption.locationInterval = 1000;
    // 安卓端定位精度
    locationOption.locationMode = AMapLocationMode.Hight_Accuracy;
    // iOS端定位最小更新距离
    locationOption.distanceFilter = -1;
    // iOS期望定位精度
    locationOption.desiredAccuracy = DesiredAccuracy.Best;
    // iOS端是否允许系统暂停定位
    locationOption.pausesLocationUpdatesAutomatically = false;

    _locationPlugin?.setLocationOption(locationOption);
  }

  static void requestAccuracyAuthorization() async {
    AMapAccuracyAuthorization currentAccuracyAuthorization = await _locationPlugin?.getSystemAccuracyAuthorization() ?? AMapAccuracyAuthorization.AMapAccuracyAuthorizationInvalid;
    if (currentAccuracyAuthorization == AMapAccuracyAuthorization.AMapAccuracyAuthorizationFullAccuracy) {
      log('精确定位');
    }
    else if (currentAccuracyAuthorization == AMapAccuracyAuthorization.AMapAccuracyAuthorizationReducedAccuracy) {
      log('模糊定位');
    }
    else {
      log('未知定位');
    }
  }

  //判断是否有权限
  static Future<bool> _checkPermission() async {
    Permission permission = Permission.locationAlways;
    PermissionStatus status = await permission.status;
    log('检测权限$status');
    if (status.isGranted) {
      //权限通过
      return true;
    } else if (status.isDenied) {
      //权限拒绝， 需要区分IOS和Android，二者不一样
      requestPermission(permission);
    } else if (status.isPermanentlyDenied) {
      //权限永久拒绝，且不在提示，需要进入设置界面
      openAppSettings();
    } else if (status.isRestricted) {
      //活动限制（例如，设置了家长///控件，仅在iOS以上受支持。
      openAppSettings();
    } else {
      //第一次申请
      requestPermission(permission);
    }

    return false;
  }

  //申请权限
  static void requestPermission(Permission permission) async {
    PermissionStatus status = await permission.request();
    log('权限状态$status');
    if (!status.isGranted) {
      openAppSettings();
    }
  }
}
