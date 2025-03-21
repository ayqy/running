import 'dart:convert';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:running/widget/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:running/const/theme.dart';

import 'api/record.dart';
import 'const/ui.dart';
import 'widget/numeric_text.dart';
import 'const/sport_type.dart';
import 'model/running_model.dart';
import 'util/lbs.dart';
import 'util/formatter.dart';
import 'util/log.dart';


class History extends StatefulWidget {
  const History({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HistoryState();
  }
}

class _HistoryState extends State<History> {
  Map<int, Map>? _recordsMap;
  Map? _recordsSummary;
  bool _isLoadMoreRunning = false;
  final Map<ScrollController, void Function()> _scrollerControllerMap = {};

  ScrollController _getScrollController(int index) {
    ScrollController controller = ScrollController();
    void callback() {
      _loadMore(controller, index);
    }
    controller.addListener(callback);
    _scrollerControllerMap[controller] = callback;
    return controller;
  }

  void _loadMore(ScrollController controller, int sportType) async {
    int pageIndex = _recordsMap![sportType]?['nextPageIndex'] ?? 0;
    bool hasNextPage = pageIndex != -1;
    if (hasNextPage && _isLoadMoreRunning == false && controller.position.extentAfter < 300) {
      setState(() {
        _isLoadMoreRunning = true;
      });
      try {
        var result = await _getRecords(
          sportType: sportType,
          pageIndex: pageIndex,
        );
        List? records = result?['records'];
        int? nextPageIndex = result?['nextPageIndex'];

        if (records != null && records.isNotEmpty) {
          setState(() {
            _recordsMap![sportType]!['records']!.addAll(records);
            _recordsMap![sportType]!['nextPageIndex'] = nextPageIndex;
          });
        } else {
          setState(() {
            _recordsMap![sportType]!['nextPageIndex'] = -1;
          });
        }
      } catch (err) {
        log(err);
      }

      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  _getRecordsSummary() async {
    var result = await RecordAPI.sum();
    setState(() {
      _recordsSummary = result;
    });
  }

  _getRecords({ required int sportType, int? pageIndex = 0 }) async {
    Map conditions = {
      'sportType': sportType,
    };
    var result = await RecordAPI.query(
      conditions: conditions,
      pageIndex: pageIndex,
    );
    List records = result['list'];
    // 起终点逆地理转回地址
    if (records.isNotEmpty) {
      List<Map> positions = [];
      for (var record in records) {
        Map startPosition = record['startPosition'] is String ? jsonDecode(record['startPosition']) : record['startPosition'];
        Map endPosition = record['endPosition'] is String ? jsonDecode(record['endPosition']) : record['endPosition'];
        positions.add({
          'lon': startPosition['longitude'],
          'lat': startPosition['latitude'],
        });
        
        positions.add({
          'lon': endPosition['longitude'],
          'lat': endPosition['latitude'],
        });
      }
      List addresses = await LBS.batchRegeo(positions);
      for (int i = 0; i < addresses.length; i+=2) {
        int index = (i / 2).floor();
        records[index]['startAddress'] = Formatter.formatAddress(addresses[i]);
        records[index]['endAddress'] = Formatter.formatAddress(addresses[i + 1]);
      }
    }
    return {
      'nextPageIndex': result['nextPageIndex'],
      'records': records,
    };
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(image: AssetImage('images/empty.png')),
          Text('还没有记录哦', style: TextStyle(color: ThemeColors.regularTextColor)),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    if (_recordsSummary == null || _recordsSummary!.isEmpty) {
      return _buildEmptyView();
    }

    List keys = _recordsSummary!.keys.toList();
    keys.sort();
    return Column(
      children: keys.map((sportType) {
        Map summary = _recordsSummary![sportType];
        String formattedDistance = '0.0';
        String formattedDuration = "0.0";
        String formattedKcal = '0';

        Map type = SportType.fromValue(sportType is String ? int.parse(sportType) : sportType);
        IconData icon = type['icon'];
        bool isRunning = type == SportType.running;
        int duration = summary['duration'];
        double distance = summary['distance'];
        if (duration > 0) {
          formattedDuration = Formatter.formatDuration(duration, true);
        }
        if (distance > 1) {
          double mps = distance / duration;
          double kcal = duration <= 1 ? 0 : Formatter.getKcal(duration, mps, 60, isRunning);
          formattedDistance = Formatter.formatDistance(distance);
          formattedKcal = Formatter.formatKcal(kcal);
        }

        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    stops: [0, 1],
                    colors: ThemeColors.navBarGradientColors
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  NumericText(
                    text: formattedDistance,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                  Text(isRunning ? '累计跑过(km)' : '累计里程(km)', style: TextStyle(color: ThemeColors.regularTextColor)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            NumericText(
                              text: summary['count'].toString(),
                              color: ThemeColors.valueTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                            Text('次数', style: TextStyle(color: ThemeColors.regularTextColor)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            NumericText(
                              text: formattedDuration,
                              color: ThemeColors.valueTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                            Text('时长(小时)', style: TextStyle(color: ThemeColors.regularTextColor)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            NumericText(
                              text: formattedKcal,
                              color: ThemeColors.valueTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                            Text('热量(kcal)', style: TextStyle(color: ThemeColors.regularTextColor)),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              )
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: const Offset(-8, -5),
                child: Icon(icon, size: 100, color: ThemeColors.backgroundColor),
              ),
            ),
          ]
        );
      }).toList(),
    );
  }

  Widget _buildList(int index) {
    if (index == 0) {
      return _buildSummary();
    }

    List records = _recordsMap![index]?['records'] ?? [];
    int nextPageIndex = _recordsMap![index]?['nextPageIndex'] ?? 0;
    bool hasNextPage = nextPageIndex != -1;
    if (records.isEmpty) {
      return _buildEmptyView();
    }

    List<Widget> children = records.map((record) {
      String formattedDistance = '0.0';
      String formattedDuration = "00:00:00";
      String formattedSpeed = "0'00";
      String formattedKcal = '0';

      IconData icon = SportType.fromValue(record['sportType'])['icon'];
      bool isRunning = SportType.fromValue(record['sportType']) == SportType.running;
      String speedText = isRunning ? '配速' : '均速(km/h)';
      int duration = record['duration'];
      double distance = record['distance'];
      if (duration > 0) {
        formattedDuration = Formatter.formatDuration(duration);
      }
      if (distance > 1) {
        double mps = distance / duration;
        double kcal = duration <= 1 ? 0 : Formatter.getKcal(duration, mps, 60, isRunning);
        formattedDistance = Formatter.formatDistance(distance);
        formattedSpeed = Formatter.formatSpeed(mps, !isRunning);
        formattedKcal = Formatter.formatKcal(kcal);
      }

      return Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        decoration: BoxDecoration(
            color: ThemeColors.cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: ThemeColors.dividerColor.withOpacity(0.05),
              style: BorderStyle.solid,
              width: 1,
            )
        ),
        child: Column(
          children: [
            // 日期
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      stops: [0.0, 1.0],
                      colors: [Color(0xff5cc99f), Color(0xff6adeb9)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xff68dab4),
                        ),
                        child: Icon(icon, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 2),
                      Text(
                          isRunning ? '跑步锻炼' : '骑行运动',
                          style: const TextStyle(color: Colors.white)
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                NumericText(
                    text: formatDate(DateTime.fromMillisecondsSinceEpoch(record['startTime']), [yyyy, '-', mm, '-', dd]),
                    fontSize: 16,
                    color: ThemeColors.regularTextColor
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 起点
            Row(
              children: [
                Column(
                  children: [
                    Text('起点', style: TextStyle(color: ThemeColors.regularTextColor)),
                    Text('终点', style: TextStyle(color: ThemeColors.regularTextColor)),
                  ],
                ),
                const SizedBox(width: 6),
                Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: const Color(0xff64d5a3),
                        ),
                        child: const SizedBox(width: 10, height: 10),
                      ),
                      Container(
                        height: 10,
                        width: 1,
                        color: const Color.fromRGBO(43, 43, 43, 0.2),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: const Color(0xffec6f6a),
                        ),
                        child: const SizedBox(width: 10, height: 10),
                      ),
                    ]
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record['startAddress'].toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(color: ThemeColors.valueTextColor),
                        ),
                        Text(
                          record['endAddress'].toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(color: ThemeColors.valueTextColor),
                        ),
                      ]
                  ),
                ),
              ],
            ),
            Divider(height: 20, thickness: 1, color: ThemeColors.dividerColor.withOpacity(0.1)),
            // 指标
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      NumericText(
                        text: formattedDistance,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.valueTextColor,
                      ),
                      Text('距离(km)', style: TextStyle(color: ThemeColors.regularTextColor)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      NumericText(
                        text: formattedDuration,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.valueTextColor,
                      ),
                      Text('时长', style: TextStyle(color: ThemeColors.regularTextColor)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      NumericText(
                        text: formattedSpeed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.valueTextColor,
                      ),
                      Text(speedText, style: TextStyle(color: ThemeColors.regularTextColor)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      NumericText(
                        text: formattedKcal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.valueTextColor,
                      ),
                      Text('热量(kcal)', style: TextStyle(color: ThemeColors.regularTextColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
    // 正在加载下一页
    if (_isLoadMoreRunning == true) {
      children.add(Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ));
    }
    // 没有下一页
    if (!hasNextPage) {
      children.add(Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: const Center(
          child: Text(
            '—— 没有更多记录了 ——',
            style: TextStyle(color: Color(0xffaaaaaa)),
          ),
        ),
      ));
    }
    return ListView(
      controller: _getScrollController(index),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: children,
    );
  }

  Widget _wrapBackgroundContainer(Widget child) {
    return Container(
      color: ThemeColors.backgroundColor,
      child: child,
    );
  }

  @override
  initState() {
    super.initState();

    // 直接请求统计数据，无依赖
    _getRecordsSummary();
    // 请求历史记录
    // 用来合并到一次setState
    Map<int, Map> tmpRecordsMap = {};
    List<int> sportTypes = SportType.values();
    sportTypes.forEach((sportType) async {
      Map result = await _getRecords(sportType: sportType);
      tmpRecordsMap[sportType] = result;
      // 当前tab下的数据回来了就先展示
      if (mounted) {
        RunningModel model = Provider.of<RunningModel>(context, listen: false);
        if (model.sportType['value'] == sportType) {
          EasyLoading.dismiss();
          setState(() {
            _recordsMap = tmpRecordsMap;
          });
        }
        // 比当前tab数据回来晚的要刷UI
        else if (_recordsMap != null) {
          setState(() {
            _recordsMap = tmpRecordsMap;
          });
        }
      }
    });
  }

  @override
  dispose() {
    super.dispose();
    EasyLoading.dismiss();
    _scrollerControllerMap.forEach((controller, callback) {
      controller.removeListener(callback);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RunningModel>(
      builder: (context, RunningModel model, child) {
        int initialIndex = model.sportType['value'];
        List<Map> tabs = [{
          'text': '累计',
          'icon': Icons.bar_chart,
        }, {
          'text': '跑步',
          'icon': Icons.directions_run_sharp,
        }, {
          'text': '骑行',
          'icon': Icons.directions_bike_sharp,
        }];
        List<Widget> body;
        if (_recordsMap == null) {
          body = tabs.map((_) => _wrapBackgroundContainer(const SizedBox())).toList();
          EasyLoading.show(status: 'loading...');
        }
        else if (_recordsMap!.isNotEmpty) {
          body = [0, ...SportType.values()].map((index) => _wrapBackgroundContainer(_buildList(index))).toList();
        }
        else {
          body = tabs.map((_) => _wrapBackgroundContainer(_buildEmptyView())).toList();
        }

        return DefaultTabController(
          initialIndex: initialIndex,
          length: tabs.length,
          child: Scaffold(
            appBar: CustomAppBar(
              title: '历史记录',
              bottom: TabBar(
                labelColor: Colors.white,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2.0, color: Colors.white),
                  insets: EdgeInsets.symmetric(horizontal: 30.0, vertical: 5),
                ),
                labelPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                tabs: tabs.map((tab) =>
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab['icon'],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(tab['text']),
                      ],
                    ),
                  )
                ).toList(),
              ),
            ),
            body: TabBarView(
              children: body,
            ),
          ),
        );
      }
    );
  }
}