import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluwx/fluwx.dart';
import 'package:running/util/color.dart';
import 'const/icon.dart';
import 'util/log.dart';
import 'util/toast.dart';
import 'const/running_status.dart';
import 'widget/numeric_text.dart';
import 'model/running_model.dart';
import 'util/formatter.dart';
import 'util/converter.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DashboardWidgetState();
}

class DashboardWidgetState extends State<Dashboard> {
  // 分享朋友圈
  _shareWeChatTimeline() async {
    // todo universalLink需要付费Apple ID，暂时做不了
    bool result = await isWeChatInstalled;
    if (!result) {
      return toast('未安装微信，无法分享');
    }
    var model = WeChatShareWebPageModel(
      //链接
      'http://cdn.ayqy.net/app/running/index.html',
      //标点
      title: "跑起来就有风",
      //小图
      thumbnail: WeChatImage.network('http://cdn.ayqy.net/app/running/icon-108x108.png'),
      //微信消息
      scene: WeChatScene.SESSION,
    );
    // WeChatShareImageModel(
    //   WeChatImage.network('http://cdn.ayqy.net/app/running/icon-108x108.png'),
    //   thumbnail: WeChatImage.network('http://cdn.ayqy.net/app/running/icon-108x108.png'),
    //   scene: WeChatScene.TIMELINE,
    // )
    shareToWeChat(model);
  }

  Widget _buildFieldView(value, desc) {
    return Expanded(
      child: Column(
        children: [
          NumericText(
            text: value,
            color: Colors.black,
          ),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      )
    );
  }

  Widget _buildSummaryCard(RunningModel model) {
    String formattedDistance = '0.0';
    String formattedDuration = "00:00:00";
    String formattedSpeed = "0'00\"";
    String formattedKcal = '0';

    IconData icon = model.sportType['icon'];
    int duration = model.getDuration();
    double distance = model.getDistance();
    if (duration > 0) {
      formattedDuration = Formatter.formatDuration(duration);
    }
    if (distance > 1) {
      double mps = distance / duration;
      double kcal = duration <= 1 ? 0 : Formatter.getKcal(duration, mps);
      formattedDistance = Formatter.formatDistance(distance);
      // 最近1.x公里的配速，避免刚过整数公里时配速不准，往前多算1公里
      List<int> kmDurations = model.getKMDurations();
      int leadingKMDuration = [0, ...kmDurations.sublist(0, max(kmDurations.length - 1, 0))].reduce((a, b) => a + b);
      int segmentDuration = duration - leadingKMDuration;
      double segmentDistance = distance - max(kmDurations.length - 1, 0) * 1000;
      double segmentSpeed = segmentDistance / segmentDuration;
      formattedSpeed = Formatter.formatSpeed(segmentSpeed);
      formattedKcal = Formatter.formatKcal(kcal);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 里程信息卡
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.ideographic,
          children: [
            Container(
              transform: Matrix4.translationValues(0, 3, 0),
              child: Icon(
                icon,
                size: 36,
                color: Colors.orange,
              ),
            ),
            const SizedBox(
              width: 6,
            ),
            NumericText(
              text: formattedDistance,
              fontSize: 48,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            const NumericText(
              text: 'km',
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        Row(
          children: [
            const Text(
              '慢',
              style: TextStyle(
                color: Colors.green,
              ),
            ),
            Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    stops: [0.0, 0.5, 1.0],
                    colors: [Colors.green, Colors.yellow, Colors.red],
                  ),
                ),
              ),
            ),
            const Text(
              '快',
              style: TextStyle(
                  color: Colors.red
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildFieldView(formattedDuration, '时长'),
            _buildFieldView(formattedSpeed, '配速(min/km)'),
            _buildFieldView(formattedKcal, '热量(kcal)'),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedPerKMCard(RunningModel model) {
    const double BAR_HEIGHT = 24;
    List<int> kmDurations = model.getKMDurations();
    // 没数据不展示
    if (kmDurations.isEmpty) {
      return const SizedBox();
    }
    int maxDuration = kmDurations.reduce(max);
    List<double> speedPerKM = kmDurations.map((duration) => 1000 / duration).toList();
    double maxSpeed = speedPerKM.reduce(max);
    // 平均配速（全程）
    int duration = model.getDuration();
    double distance = model.getDistance();
    double mps = distance / duration;
    String avgSpeed = Formatter.formatSpeed(mps);

    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  const Text('平均配速'),
                  NumericText(
                    text: avgSpeed,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              )
            ),
            Expanded(
                flex: 1,
                child: Column(
                  children: [
                    const Text('最快配速'),
                    NumericText(
                      text: Formatter.formatSpeed(maxSpeed),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                )
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Text('公里', style: TextStyle(color: Color(0xff555555))),
            SizedBox(width: 20),
            Text('配速(min/km)', style: TextStyle(color: Color(0xff555555))),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: speedPerKM.asMap().map((index, speed) {
            // 每5km分一段
            int currentKM = (index + 1);
            bool isSegment = currentKM % 5 == 0;
            int timeSpent = kmDurations.sublist(0, index + 1).reduce((a, b) => a + b);

            return MapEntry(index, Column(
              children: [
                Container(
                    height: BAR_HEIGHT,
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(BAR_HEIGHT),
                        color: const Color(0xffeeeeee),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          // 宽度百分比根据整体最大值来，最大0.9，最小0.2
                          widthFactor: 0.2 + 0.7 * kmDurations[index] / maxDuration,
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(BAR_HEIGHT),
                                // 速度取真实m/s速度
                                color: ColorUtil.withOpacity(ColorUtil.mapSpeedToColor(speed), 0.85),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    offset: Offset(0, 1),
                                    blurRadius: 1,
                                    spreadRadius: 0,
                                  ),
                                ]
                            ),
                            child: Row(
                              children: [
                                // 第几公里
                                const SizedBox(width: 10),
                                Center(
                                  child: Text((index + 1).toString(), style: const TextStyle(color: Colors.white)),
                                ),
                                const Spacer(flex: 1),
                                // 配速
                                Center(
                                  child: Text(Formatter.formatSpeed(speed), style: const TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                ),
                Visibility(
                  visible: isSegment,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "$currentKM公里  累计用时 ${Formatter.formatDuration(timeSpent)}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ));
          }).values.toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RunningModel>(
      builder: (context, RunningModel model, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 统计信息卡
                  _buildSummaryCard(model),
                  // 每公里配速卡
                  _buildSpeedPerKMCard(model),
                ],
              ),
              Consumer<RunningModel>(
                builder: (context, RunningModel model, child) =>
                  Visibility(
                    visible: false,
                    // visible: model.status == RunningStatus.done,
                    child: Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(MyIcon.share),
                        color: Colors.orange,
                        onPressed: _shareWeChatTimeline
                      )
                    ),
                  ),
              ),
            ],
          ),
        );
      }
    );
  }
}
