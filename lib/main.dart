import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:provider/provider.dart';
import 'package:fluwx/fluwx.dart';
import 'const/sport_type.dart';
import 'const/ui.dart';
import 'settings.dart';
import 'account_settings.dart';
import 'about.dart';
import 'api/record.dart';
import 'const/secret_config.dart';
import 'util/date.dart';
import 'util/device.dart';
import 'const/storage_key.dart';
import 'login.dart';
import 'map/map_widget_amap.dart';
import 'profile.dart';
import 'history.dart';
import 'util/storage.dart';
import 'util/toast.dart';
import 'map/map_location_location.dart';
import 'main_button.dart';
import 'dashboard.dart';
import 'model/running_model.dart';
import 'util/map.dart';
import 'debug_panel.dart';
import 'util/tts/tts.dart';
import 'util/toast.dart';
import 'util/formatter.dart';
import 'util/tts/nonsenses.dart';
import 'util/audio.dart';
import 'util/account.dart';
import 'util/log.dart';
import 'util/noop.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 加载API Key等特殊配置常量
  await SecretConfig.load();
  runApp(
    ChangeNotifierProvider(
      create: (context) => RunningModel(),
      child: const MyApp(),
    ),
  );
  // 同意AMap隐私协议
  updateAMapPrivacy();
  // 要求始终允许访问位置信息
  await MapLocationLocation.checkPermission();
  // 初始化定位模块
  MapLocationLocation.init();
  // 初始化diu
  await DeviceUtil.init();
  // 初始化TTS模块
  TTS.init();
  // 初始化BGM模块
  AudioUtil.init();
  // 初始化微信API
  initWXApi();
  // 初始化账号信息
  AccountUtil.init();
  // 上传本地记录
  RecordAPI.syncRecords();
}

// 慎用，仅本地调试使用，不上线
void washDirtyRecords() {
  Storage.get(localKey).then((String value) async {
    List records = [];
    if (value.isNotEmpty) {
      try {
        records = jsonDecode(value);
      } catch (error) {
        log(error);
        // 历史记录坏了，丢掉
        throw AssertionError('历史记录坏了，无法清洗数据');
      }
      log('共${records.length}条本地数据');
      List washedRecords = [];
      records.forEach((record) {
        if (record is String) {
          // 老格式，decode一下
          washedRecords.add(jsonDecode(record));
          log('洗了1条旧格式数据');
        }
        else if (record is Map) {
          // 新格式保持不变
          DateTime startTime = DateTime.fromMillisecondsSinceEpoch(record['startTime']);
          if (DateUtil.isToday(startTime)) {
            record.remove('uploaded');
            log('重传今天的数据');
          }
          washedRecords.add(record);
        }
      });
      log('洗完共${washedRecords.length}条本地数据');
      log(washedRecords);
      Storage.set(localKey, jsonEncode(washedRecords)).then((_) {
        log('洗数据完成');
      });
    }
  });
}

///微信登录初始化
void initWXApi() async {
  bool result = await registerWxApi(
    appId: SecretConfig.get('WX_APP_ID'),
    doOnAndroid: false,
    doOnIOS: true,
    universalLink: SecretConfig.get('WX_UNIVERSAL_LINKS'),
  );
  if (!result) {
    log('>>>>>WXApi init Failed');
    log(result);
  }
  // 监听回调
  weChatResponseEventHandler.listen((res) {
    log('>>>>>weChatResponseEvent');
    log(res);
    if (res is WeChatPaymentResponse) {
      // do something here
    }
  });
}

/// AMap SDK隐私权限免责声明
void updateAMapPrivacy() {
  AMapFlutterLocation.updatePrivacyAgree(true);
  AMapFlutterLocation.updatePrivacyShow(true, true);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Running',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      builder: EasyLoading.init(),
      home: const MyHomePage(title: 'Just Run'),
      routes: <String, WidgetBuilder>{
        '/history': (BuildContext context) => const History(),
        '/login': (BuildContext context) => const Login(),
        '/account_settings': (BuildContext context) => const AccountSettings(),
        '/settings': (BuildContext context) => const Settings(),
        '/about': (BuildContext context) => const About(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// 定制浮动按钮的位置
class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  FloatingActionButtonLocation location;
  double offsetX;    // X方向的偏移量
  double offsetY;    // Y方向的偏移量
  CustomFloatingActionButtonLocation(this.location, this.offsetX, this.offsetY);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    Offset offset = location.getOffset(scaffoldGeometry);
    return Offset(offset.dx + offsetX, offset.dy + offsetY);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final double _initFabHeight = UIConsts.SLIDING_PANEL_INITIAL_HEIGHT;
  double _fabHeight = 0;
  double _panelHeightOpen = 0;
  final double _panelHeightClosed = UIConsts.SLIDING_PANEL_INITIAL_HEIGHT;

  GlobalKey<DashboardWidgetState> _dashboardKey = GlobalKey<DashboardWidgetState>();
  GlobalKey<MapWidgetAMapState> _mapKey = GlobalKey<MapWidgetAMapState>();
  GlobalKey<MainButtonWidgetState> _mainButtonKey = GlobalKey<MainButtonWidgetState>();
  GlobalKey<DebugPanelWidgetState> _debugPanelKey = GlobalKey<DebugPanelWidgetState>();
  Timer? timer;
  Map<String, Object>? lastPosition;
  bool _easterEggEnabled = false;
  bool _enabelDrawPoints = false;
  int lastCompletedKm = 0;
  int lastKmCompletedTime = 0;
  bool isMusicActive = false;

  speak(text, {Map<String, Object>? options = const {}, pauseBeforeSpeaking = true, playAfterSpeaking = true}) {
    if (isMusicActive && pauseBeforeSpeaking) {
      AudioUtil.pause();
    }
    return TTS.speak(text, options).then((_) {
      if (isMusicActive && playAfterSpeaking) {
        AudioUtil.play();
      }
    });
  }

  onLocationChanged(Map<String, Object> location, RunningModel model) {
    // {latitude: 39.96457835586144, longitude: 116.44195356407825, accuracy: 81.51009359402404, altitude: 44.047287940979004, speed: 0.0, speedAccuracy: 0.4099999964237213, heading: -1.0, time: 1653739756999.074, isMock: false, locationType: 1}
    // log(location);
    if (_easterEggEnabled) {
      _debugPanelKey.currentState?.updateLocation(location);
    }
    double latitude = double.parse(location['latitude'].toString());
    double longitude = double.parse(location['longitude'].toString());
    // 记录起点
    if (model.getStartPosition() == null) {
      model.setStartPosition(location);
    }
    // 计算与上一个位置的直线距离，累加成distance
    if (lastPosition != null) {
      double lastLat = double.parse(lastPosition!['latitude'].toString());
      double lastLng = double.parse(lastPosition!['longitude'].toString());
      double distance = MapUtil.distanceBetween(latitude, longitude, lastLat, lastLng);
      double totalDistance = model.countDistance(distance);
      int completedKm = (totalDistance / 1000).truncate();
      // 秒 转 xx分xx秒
      if (completedKm > lastCompletedKm) {
        // 每跑过1km，都临时存一下，防止数据丢失
        _saveRecordBackup(model);
        int now = DateTime.now().millisecondsSinceEpoch;
        int startTime = model.getStartTime();
        int lastKmTimeSpent = lastKmCompletedTime == 0 ? now - startTime : now - lastKmCompletedTime;
        // 记录每公里配速
        int lastKMDuration = (lastKmTimeSpent / 1000).truncate();
        model.recordKMDurations(lastKMDuration);
        String formattedLastKmTimeSpent = Formatter.formatDurationAsTTSString(lastKmTimeSpent);
        Map sportType = model.sportType;
        speak('你已${sportType == SportType.running ? '跑步' : '骑行'}$completedKm公里，最近一公里用时$formattedLastKmTimeSpent，加油');
        lastCompletedKm = completedKm;
        lastKmCompletedTime = now;
      }

      if (_easterEggEnabled) {
        double totalDistance = model.getDistance();
        _debugPanelKey.currentState?.updateDistance(totalDistance);
      }
    }
    // 地图画轨迹
    _mapKey.currentState?.drawPath(MapLocationLocation.getLocationTrack());
    if (_enabelDrawPoints) {
      // 画点
      _mapKey.currentState?.drawPoint(latitude, longitude);
    }
    // 记录上一个点
    lastPosition = location;
  }

  start(RunningModel model) {
    model.setStartTime(DateTime.now().millisecondsSinceEpoch);
    MapLocationLocation.startLocation((location) {
      onLocationChanged(location, model);
    });
    _clearStates();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      model.countDuration();
    });
    // 读句鸡汤
    Nonsenses.shuffle();
    String nonsense = Nonsenses.next();
    String sportType = model.sportType['label'];
    speak("$sportType开始！", options: { 'rate': 0.65 }).then((_) {
      speak(nonsense);
    });
  }

  _clearStates() {
    _mapKey.currentState?.clear();
    _debugPanelKey.currentState?.reset();
  }

  _saveRecord(RunningModel model) {
    const int minMinutes = 3;
    if (model.getDuration() < minMinutes * 60) {
      // 时间太短，不计入历史记录
      return;
    }

    Storage.get(localKey).then((String value) {
      List records = [];
      if (value.isNotEmpty) {
        try {
          records = jsonDecode(value);
        } catch(error) {
          log(error);
          // 历史记录坏了，另存当次记录
          _saveRecordBackup(model).then((_) {
            toast('记得放松肌肉，补充水分哦！');
          });
          return;
        }
      }
      Map record = model.toMap();
      records.add(record);
      Storage.set(localKey, jsonEncode(records)).then((_) {
        toast('记得放松肌肉，补充水分哦');
      });
      RecordAPI.create(record).then((result) {
        if (result != false) {
          // 上传成功，更新本地记录标识
          record['uploaded'] = 1;
          Storage.set(localKey, jsonEncode(records));
        }
      });
    });
  }

  _saveRecordBackup(RunningModel model) {
    Map record = model.toMap();
    return Storage.set(tmpLocalKey, jsonEncode(record));
  }

  stop(RunningModel model, [bool saveRecord = true]) {
    // 记录结束时间
    model.setEndTime(DateTime.now().millisecondsSinceEpoch);
    // 记录终点
    model.setEndPosition(MapLocationLocation.getLocation());
    // 持久化
    if (saveRecord) {
      _saveRecord(model);
    }
    // 清理状态
    timer?.cancel();
    setState(() {
      timer = null;
    });
    MapLocationLocation.stopLocation();
    lastPosition = null;
  }

  reset() {
    RunningModel model = Provider.of<RunningModel>(context, listen: false);
    stop(model, false);
    _clearStates();
    model.reset();
    _mainButtonKey.currentState?.reset();
  }

  clearLocalData() {
    Storage.removeAll();
  }

  /// 显示/隐藏开发者彩蛋
  void _toggleEasterEgg() async {
    setState(() {
      _easterEggEnabled = !_easterEggEnabled;
    });
  }

  void enableDrawPoints(enabled) {
    _enabelDrawPoints = enabled;
  }

  LatLng? _getLocation() {
    Map<String, Object>? location = MapLocationLocation.getLocation();
    if (location != null) {
      double latitude = double.parse(location['latitude'].toString());
      double longitude = double.parse(location['longitude'].toString());
      return LatLng(latitude, longitude);
    }
    return null;
  }

  bool _toggleMusic() {
    if (isMusicActive) {
      AudioUtil.stop();
    }
    else {
      AudioUtil.play();
    }
    isMusicActive = !isMusicActive;
    return isMusicActive;
  }

  @override
  initState() {
    super.initState();
    _fabHeight = _initFabHeight;
    // 监听定位变化
    MapLocationLocation.onReady((location) {
      double latitude = double.parse(location['latitude'].toString());
      double longitude = double.parse(location['longitude'].toString());
      // 移动地图
      _mapKey.currentState?.setMapCenter(LatLng(latitude, longitude));
    });
  }

  Widget _panel(ScrollController sc) {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView(
          controller: sc,
          children: [
            const SizedBox(
              height: 5.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 30,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.all(Radius.circular(12.0))),
                ),
              ],
            ),
            Dashboard(
              key: _dashboardKey,
            ),
          ]
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _panelHeightOpen = MediaQuery.of(context).size.height * 0.65;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: UIConsts.APPBAR_TOOLBAR_HEIGHT,
        leading: TextButton(
          onLongPress: _toggleEasterEgg,
          onPressed: noop,
          child: const Text(
            'EGG',
            style: TextStyle(
              color: Colors.transparent,
            ),
          ),
        ),
        title: Text(widget.title),
        flexibleSpace: UIConsts.APPBAR_FLEXIBLE_SPACE,
      ),
      drawer: const Drawer(
        elevation: 16,
        child: Profile(),
      ),
      body: SlidingUpPanel(
        maxHeight: _panelHeightOpen,
        minHeight: _panelHeightClosed,
        parallaxEnabled: true,
        parallaxOffset: 0.5,
        boxShadow: [
          const BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        body: Center(
          child: Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: MapWidgetAMap(
                        key: _mapKey,
                        getLocation: _getLocation,
                        toggleMusic: _toggleMusic
                    ),
                  ),
                ],
              ),
              Consumer<RunningModel>(
                builder: (context, RunningModel model, child) =>
                  Positioned(
                    bottom: UIConsts.SLIDING_PANEL_INITIAL_HEIGHT + 10,
                    child: MainButton(
                      key: _mainButtonKey,
                      onStart: () { start(model); },
                      onStop: () { stop(model); },
                      speak: speak,
                    ),
                  ),
              ),

              Visibility(
                  visible: _easterEggEnabled,
                  child: Positioned(
                    left: 0,
                    top: 0,
                    child: DebugPanel(
                      key: _debugPanelKey,
                      enableRandomOffset: MapLocationLocation.enableRandomOffset,
                      enableDrawPoints: enableDrawPoints,
                      reset: reset,
                      clearLocalData: clearLocalData,
                    ),
                  )
              )
            ],
          ),
        ),
        panelBuilder: (sc) => _panel(sc),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
        onPanelSlide: (double pos) => setState(() {
          _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
        }),
      ),
    );
  }
}
