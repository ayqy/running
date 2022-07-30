import 'package:flutter/material.dart';

class NumericText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const NumericText({Key? key, required this.text, this.fontSize, this.fontWeight, this.color}) : super(key: key);

  split(String s, String splitter) {
    List<String> parts = s.split(splitter);
    List<String> partsWithSplitter = [];
    for (var part in parts) {
      partsWithSplitter.add(part);
      partsWithSplitter.add(splitter);
    }
    return partsWithSplitter.isEmpty ? [s] : partsWithSplitter.getRange(0, partsWithSplitter.length - 1).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 绕过x.4小数点被塞进4下边的诡异问题，拆成3个TextView展示
    if (text.contains('.')) {
      List<Widget> children = split(text, '.').map<Widget>((txt) {
        return Text(
          txt,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            fontFamily: 'Abel',
          ),
        );
      }).toList();

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontFamily: 'Abel',
      ),
    );
  }
}
