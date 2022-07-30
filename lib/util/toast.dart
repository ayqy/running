import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void toast(msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.7),
      textColor: Colors.white,
      fontSize: 14.0
  );
}
