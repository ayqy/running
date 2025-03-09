import 'package:flutter/material.dart';

import 'noop.dart';

class MyDialog {
  static void confirm(BuildContext context, var content, Function confirmCallback, {String? title}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title ?? "提示", style: const TextStyle(color: Colors.orange)),
          content: content is String ? Text(content) : content,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                confirmCallback(() {
                  Navigator.of(context).pop();
                });
              },
              child: const Text("确认"),
            ),
          ],
        );
      });
  }

  static void alert(BuildContext context,String content, { String title = '提示', String buttonText = '我知道了', Function onPressed = noop }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.orange)),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                onPressed();
                Navigator.of(context).pop();
              },
              child: Text(buttonText),
            ),
          ],
        );
      });
  }
}
