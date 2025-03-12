import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:provider/provider.dart';
import 'package:running/const/ui.dart';
import '../const/icon.dart';
import '../model/running_model.dart';
import '../const/sport_type.dart';
import '../util/map.dart';
import 'map_config_amap.dart';
import '../util/color.dart';
import '../widget/radio_group.dart';
import '../util/account.dart';

class MapWidgetAMap extends StatefulWidget {
  final getLocation;
  final toggleMusic;
  const MapWidgetAMap({Key? key, this.getLocation, this.toggleMusic}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MapWidgetAMapState();
}

class MapWidgetAMapState extends State<MapWidgetAMap> with TickerProviderStateMixin {
  final Map<String, Polyline> _polylines = <String, Polyline>{};
  // index游标，表示画到哪个轨迹点了
  int _drawnCursor = 0;
  final Map<String, Marker> _markers = <String, Marker>{};
  AMapController? _mapController;
  // 当前图面中心点
  LatLng? _mapCenter;
  // 当前缩放等级
  double _zoomLevel = 18;
  // 矩形的polyline id
  String? _rectId;
  // 图面元素的外接矩形西南角
  LatLng? _southwest;
  // 图面元素的外接矩形东北角
  LatLng? _northeast;
  // 全览区域的padding
  final double mapOverviewPadding = 50;
  // 地图下边界的bottom
  final double mapBottomOffset = 160;
  // todo 暂时先写死，应该跟着bounding走
  double bottomHeight = UIConsts.SLIDING_PANEL_INITIAL_HEIGHT + 10;
  // 经验值，修正地图bottomHeight
  double get mapBottomHeight => mapBottomOffset * window.devicePixelRatio / 2;
  // 是否正在播放音乐
  bool isMusicWidgetActive = false;
  // 旋转动画controller
  AnimationController? animationController;
  // 登录后的用户头像
  String avatar = '';

  @override
  void initState() {
    super.initState();
    AccountUtil.onChange((_) {
      setState(() {
        avatar = AccountUtil.getAvatarUrl();
      });
    });
  }

  void moveCamera(LatLng? mapCenter) {
    if (mapCenter != null) {
      mapCenter = patchMapPadding(mapCenter, yOffset: -mapBottomHeight / 2);
      _mapController?.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: mapCenter,
        zoom: _zoomLevel,
      )));
    }
  }

  // 根据地图可见区域对经纬度做偏移补偿（解决无法设置底部大padding的问题）
  LatLng patchMapPadding(LatLng point, { double xOffset = 0, double yOffset = 0 }) {
    LatLng offset = MapUtil.offsetPixel(
      point,
      _zoomLevel,
      xOffset: xOffset,
      yOffset: yOffset,
    );
    return offset;
  }

  void setZoomLevel(double zoomLevel) {
    if (_mapCenter != null) {
      _mapController?.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: _mapCenter!,
        zoom: zoomLevel,
      )));
    }
  }

  void setBounding(LatLng? southwest, LatLng? northeast) {
    if (southwest != null && northeast != null) {
      // 只偏西南角，让底部多留一些padding
      southwest = patchMapPadding(southwest, yOffset: -(mapBottomHeight + mapOverviewPadding));
      // 调试：画出来看看边界
      // _drawRect(southwest, northeast, Colors.blue);
      if (southwest.latitude > northeast.latitude) {
        // 西南角纬度超过了东北角纬度，LatLngBounds会报错崩溃，忽略本次调用
        return;
      }
      _mapController?.moveCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: southwest,
          northeast: northeast,
        ),
        mapOverviewPadding,
      ));
    }
  }

  void setMapCenter(LatLng position) {
    if (_mapController != null) {
      moveCamera(position);
    }
    else {
      _mapCenter = position;
    }
  }

  List<LatLng> _getPoints(List<Map<String, Object>> locationTrack, int startIndex) {
    final List<LatLng> points = <LatLng>[];
    for(int i = startIndex; i < locationTrack.length; i++) {
      Map<String, Object> location = locationTrack[i];
      double lat = double.parse(location['latitude'].toString());
      double lng = double.parse(location['longitude'].toString());
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  void drawPath(List<Map<String, Object>>? locationTrack) {
    if (locationTrack == null) {
      return;
    }

    setState(() {
      List<LatLng> points = _getPoints(locationTrack, _drawnCursor);
      for(int i = 0; i < points.length - 1; i++) {
        List<LatLng> segment = [
          points[i],
          points[i+1],
        ];
        double startSpeed = locationTrack[_drawnCursor+i]['speed'] as double;
        double endSpeed = locationTrack[_drawnCursor+i+1]['speed'] as double;
        final Polyline polyline = Polyline(
          color: ColorUtil.getSegmentColor(startSpeed, endSpeed),
          width: 10,
          points: segment,
          capType: CapType.square,
        );
        _polylines[polyline.id] = polyline;
      }
      _drawnCursor = locationTrack.length - 1;
    });
    // 全览
    overview(locationTrack);
  }

  void overview(List<Map<String, Object>> locationTrack) {
    // 找出西南角和东北角
    LatLng firstPoint = LatLng(locationTrack[0]['latitude'] as double, locationTrack[0]['longitude'] as double);
    LatLng southwest = firstPoint;
    LatLng northeast = firstPoint;
    for(int i = 1; i < locationTrack.length; i++) {
      double latitude = locationTrack[i]['latitude'] as double;
      double longitude = locationTrack[i]['longitude'] as double;
      // 中国在东北半球，经纬度都是正数，左下角小，右上角大，简单计算可以满足
      // 最小纬度
      if (latitude < southwest.latitude) {
        southwest = LatLng(latitude, southwest.longitude);
      }
      // 最大纬度
      if (latitude > northeast.latitude) {
        northeast = LatLng(latitude, northeast.longitude);
      }
      // 最小经度
      if (longitude < southwest.longitude) {
        southwest = LatLng(southwest.latitude, longitude);
      }
      // 最大经度
      if (longitude > northeast.longitude) {
        northeast = LatLng(northeast.latitude, longitude);
      }
    }
    setBounding(southwest, northeast);
    _southwest = southwest;
    _northeast = northeast;

    // 本地调试：矩形画出来看看
    // _drawRect(southwest, northeast);
  }

  void _drawRect(southwest, northeast, [Color? color]) {
    setState(() {
      final Polyline polyline = Polyline(
        color: color ?? Colors.red.shade500,
        width: 2,
        dashLineType: DashLineType.square,
        points: [
          LatLng(northeast.latitude, southwest.longitude),
          northeast,
          LatLng(southwest.latitude, northeast.longitude),
          southwest,
          LatLng(northeast.latitude, southwest.longitude),
        ],
        capType: CapType.square,
      );
      if (_rectId != null) {
        _polylines.remove(_rectId);
      }
      _polylines[polyline.id] = polyline;
      _rectId = polyline.id;
    });
  }

  void drawPoint(latitude, longitude) {
    final markerPosition = LatLng(latitude, longitude);
    final Marker marker = Marker(
      alpha: 0.5,
      clickable: false,
      infoWindowEnable: false,
      position: markerPosition,
      //使用默认hue的方式设置Marker的图标
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
    //调用setState触发AMapWidget的更新，从而完成marker的添加
    setState(() {
      //将新的marker添加到map里
      _markers[marker.id] = marker;
    });
  }

  void clear() {
    setState(() {
      _markers.clear();
      _polylines.clear();
    });
  }

  void _onMapCreated(AMapController controller) {
    setState(() {
      _mapController = controller;
      moveCamera(_mapCenter);
    });
  }

  void _onCameraMoveEnd(CameraPosition position) {
    _mapCenter = position.target;
    _zoomLevel = position.zoom;
  }

  void _onLocationWidgetPressed() {
    LatLng? location = widget.getLocation();
    if (location != null) {
      moveCamera(location);
    }
  }

  void _onOverviewWidgetPressed() {
    setBounding(_southwest, _northeast);
  }

  void _onMusicWidgetPressed() {
    bool isActive = widget.toggleMusic();
    setState(() {
      isMusicWidgetActive = isActive;
    });
  }

  void _onProfileWidgetPressed() {
    // Navigator.pushNamed(context, '/profile');
    Scaffold.of(context).openDrawer();
  }

  _onSportTypeChanged(RunningModel model) {
    return (_, item) {
      model.setSportType(item);
    };
  }

  Widget _buildWidget(Widget icon, { void Function()? onPressed, bool circular = false, bool rotating = false }) {
    Widget widget = Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(circular ? 18.0 : 8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: onPressed,
            icon: icon
          ),
        ),
      ),
    );
    if (rotating) {
      if (animationController == null) {
        animationController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat();
      }
      return RotationTransition(
        //设置动画的旋转中心
        alignment: Alignment.center,
        //动画控制器
        turns: Tween<double>(
          begin: 0,
          end: 1,
        ).animate(animationController!),
        child: widget,
      );
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    AMapWidget map = AMapWidget(
      apiKey: MapConfigAMap.getAPIKeys(),
      minMaxZoomPreference: const MinMaxZoomPreference(12, 18),
      privacyStatement: MapConfigAMap.amapPrivacyStatement,
      onMapCreated: _onMapCreated,
      onCameraMoveEnd: _onCameraMoveEnd,
      polylines: Set<Polyline>.of(_polylines.values),
      markers: Set<Marker>.of(_markers.values),
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      myLocationStyleOptions: MyLocationStyleOptions(true),
    );

    bool canOverview = _polylines.values.length > 0;
    return Stack(
      children: [
        map,
        // 右上角widget
        Positioned(
          top: 20,
          right: 10,
          child: Column(
            children: [
              _buildWidget(
                avatar != '' ? CircularProfileAvatar(avatar) : const Icon(Icons.person_rounded),
                onPressed: _onProfileWidgetPressed,
                circular: true,
              ),
              const SizedBox(
                height: 10,
              ),
              _buildWidget(
                Icon(
                  isMusicWidgetActive ? Icons.music_note : Icons.music_off
                ),
                onPressed: _onMusicWidgetPressed,
                circular: true,
                rotating: isMusicWidgetActive,
              ),
            ],
          ),
        ),
        // 右下角widget
        Positioned(
          bottom: bottomHeight,
          right: 10,
          child: Column(
            children: [
              Visibility(
                visible: canOverview,
                child: _buildWidget(
                  const Icon(MyIcon.route),
                  onPressed: _onOverviewWidgetPressed
                ),
              ),
              Visibility(
                visible: canOverview,
                child: const SizedBox(
                  height: 10,
                ),
              ),
              _buildWidget(const Icon(Icons.my_location), onPressed: _onLocationWidgetPressed),
            ],
          ),
        ),
        // 左下角widget
        Positioned(
          bottom: bottomHeight,
          left: 10,
          child: Column(
            children: [
              Visibility(
                visible: !canOverview,
                child: Consumer<RunningModel>(
                  builder: (context, RunningModel model, child) {
                    return RadioGroup(
                      items: [SportType.running, SportType.ride],
                      value: model.sportType['value'],
                      onChange: _onSportTypeChanged(model),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
