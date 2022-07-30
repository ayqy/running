import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluwx/fluwx.dart';
import 'const/icon.dart';
import 'util/toast.dart';
import 'const/running_status.dart';
import 'widget/numeric_text.dart';
import 'model/running_model.dart';
import 'util/formatter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Consumer<RunningModel>(
      builder: (context, RunningModel model, child) {
        String formattedDistance = '0.0';
        String formattedDuration = "00:00:00";
        String formattedSpeed = "0'00";
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
          formattedSpeed = Formatter.formatSpeed(mps);
          formattedKcal = Formatter.formatKcal(kcal);
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 20),
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  )
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
