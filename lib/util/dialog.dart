import 'package:flutter/material.dart';

class MyDialog {
  static void confirm(BuildContext context, String content, Function confirmCallback) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("提示", style: TextStyle(color: Colors.orange)),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                confirmCallback();
                Navigator.of(context).pop();
              },
              child: const Text("确认"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("取消"),
            ),
          ],
        );
      });
  }

  static void alert(BuildContext context,String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("提示", style: TextStyle(color: Colors.orange)),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("我知道了"),
            ),
          ],
        );
      });
  }
}
