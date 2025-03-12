import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:running/const/running_status.dart';
import 'model/running_model.dart';

class MainButton extends StatefulWidget {
  final onStart;
  final onStop;
  final speak;
  const MainButton({Key? key, this.onStart, this.onStop, this.speak}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MainButtonWidgetState();
}

class MainButtonWidgetState extends State<MainButton> {
  bool starting = false;
  String countdown = '';
  Timer? timer = null;

  void countdownThenStart(Function onStart) {
    starting = true;
    widget.speak('3', playAfterSpeaking: false);
    timer = Timer(const Duration(seconds: 1), () {
      widget.speak('2', playAfterSpeaking: false);
      setState(() {
        countdown = '2';
      });
      timer = Timer(const Duration(seconds: 1), () {
        widget.speak('1', playAfterSpeaking: true);
        setState(() {
          countdown = '1';
        });
        timer = Timer(const Duration(seconds: 1), () {
          timer = null;
          setState(() {
            starting = false;
            countdown = '';
          });
          onStart();
        });
      });
    });
  }

  void reset() {
    timer?.cancel();
    setState(() {
      starting = false;
      countdown = '';
    });
  }

  void share() {
    Fluttertoast.showToast(
      msg: "分享给朋友看看吧",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black45,
      textColor: Colors.white,
      fontSize: 16.0
    );
  }

  void _onPressed(RunningModel model) {
    setState(() {
      // 未开始 - 3s倒计时 - 开始
      // 点击开始跑
      if (model.status == RunningStatus.idle) {
        if (!starting) {
          countdown = '3';
          countdownThenStart(() {
            model.setStatus(RunningStatus.running);
            if (widget.onStart != null) {
              widget.onStart();
            }
          });
        }
      }
      // 在跑 - 跑完
      // 点击跑完结束
      else if (model.status == RunningStatus.running) {
        model.setStatus(RunningStatus.done);
        widget.onStop();
      }
      // 跑完
      else if (model.status == RunningStatus.done) {
        // 不会走到2，跑完按钮消失，无法再点击
      }
    });
  }

  Widget? _buildButtonContent(RunningStatus status) {
    Widget? content;
    switch (status) {
      case RunningStatus.running:
        content = const Icon(
          Icons.close,
          color: Colors.white,
          size: 36,
        );
        break;
      case RunningStatus.done:
        break;
      default:
        content = Text(
          countdown != '' ? countdown : 'Go',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: countdown != '' ? 72 : 48,
            color: Colors.white,
          ),
        );
        break;
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RunningModel>(
      builder: (context, RunningModel model, child) {
        bool isIdle = model.status == RunningStatus.idle;
        Widget? content = _buildButtonContent(model.status);

        return SizedBox(
          width: isIdle ? 90 : 60,
          height: isIdle ? 90 : 60,
          child: content != null ? FloatingActionButton(
            backgroundColor: isIdle ? Colors.orange : Colors.red,
            onPressed: () { _onPressed(model); },
            shape: const CircleBorder(),
            child: content,
          ) : null, // This trailing comma makes auto-formatting nicer for build methods.
        );
      },
    );
  }
}
