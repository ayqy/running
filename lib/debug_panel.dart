import 'package:flutter/material.dart';
import 'package:date_format/date_format.dart';
import '../util/dialog.dart';

class DebugPanel extends StatefulWidget {
  final Function? enableRandomOffset;
  final Function? enableDrawPoints;
  final Function? reset;
  final Function? clearLocalData;

  const DebugPanel({Key? key, this.enableRandomOffset, this.enableDrawPoints, this.reset, this.clearLocalData}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DebugPanelWidgetState();
}

class DebugPanelWidgetState extends State<DebugPanel> {
  dynamic _location;
  bool _drawPoints = false;
  bool _randomOffset = false;
  int lastTimestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  double _distance = 0;

  void reset() {
    setState(() {
      _location = null;
      lastTimestamp = DateTime.now().millisecondsSinceEpoch * 1000;
      _distance = 0;
    });
  }

  updateLocation(location) {
    setState(() {
      _location = location;
    });
  }

  updateDistance(double distance) {
    setState(() {
      _distance = distance;
    });
  }

  @override
  initState() {
    super.initState();
    widget.enableDrawPoints!(_drawPoints);
    widget.enableRandomOffset!(_randomOffset);
  }

  toggleDrawPoints(on) {
    setState(() {
      _drawPoints = on;
      widget.enableDrawPoints!(on);
    });
  }

  toggleRandomOffset(on) {
    setState(() {
      _randomOffset = on;
      widget.enableRandomOffset!(on);
    });
  }

  _onReset() {
    widget.reset!();
  }

  _onClearLocalData() {
    MyDialog.confirm(context, '确认清空所有数据吗？', () {
      widget.clearLocalData!();
    });
  }

  List<Widget> _buildFieldsView() {
    List<Widget> views = <Widget>[];
    Widget refreshButton = SizedBox(
      width: 18,
      height: 18,
      child: IconButton(
        onPressed: _onReset,
        padding: const EdgeInsets.all(0),
        icon: const Icon(Icons.refresh, size: 18, color: Colors.orange,)
      ),
    );
    if (_location == null) {
      Widget clearButton = SizedBox(
        width: 18,
        height: 18,
        child: IconButton(
          onPressed: _onClearLocalData,
          padding: const EdgeInsets.all(0),
          icon: const Icon(Icons.delete_forever, size: 18, color: Colors.red,)
        ),
      );
      return [
        Row(
          children: [
            const Text('无定位信息'),
            refreshButton,
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text('清空数据', style: TextStyle(color: Colors.red)),
            clearButton,
          ],
        )
      ];
    }

    // 定位信息
    int time = (_location['time'] * 1000).truncate();
    String formattedTime = formatDate(DateTime.fromMicrosecondsSinceEpoch(time), [HH, ':', nn, ':', ss, '.', uuu]);
    int interval = ((time - lastTimestamp) / 1000).round();
    String formattedInterval = interval > 10 * 1000 ? '> 10s' : "$interval ms";
    lastTimestamp = time;
    double speed = _location['speed'];
    String formattedSpeed = speed.toStringAsFixed(2);
    String formattedDistance = _distance.toStringAsFixed(2);

    views.add(
      Row(
        children: [
          Text(formattedTime),
          refreshButton,
        ],
      )
    );
    views.add(
      Text("间隔：$formattedInterval"),
    );
    views.add(
      Text("速度：$formattedSpeed m/s"),
    );
    views.add(
      Text("距离：$formattedDistance m"),
    );
    views.add(
        Row(
          children: [
            const Text('显示扎点'),
            Switch(value: _drawPoints, onChanged: toggleDrawPoints),
          ],
        )
    );
    views.add(
        Row(
          children: [
            const Text('随机飘点'),
            Switch(value: _randomOffset, onChanged: toggleRandomOffset),
          ],
        )
    );
    return views;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.75,
      child: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildFieldsView(),
        ),
      ),
    );
  }
}
