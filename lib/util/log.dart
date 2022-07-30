import 'package:flutter/cupertino.dart';

import 'env.dart';

void log(Object? object, {int? wrapWidth, bool pipeIntoFile = false}) {
  String message = "[Running] $object";
  if (!EnvUtil.isProduction()) {
    debugPrint(message, wrapWidth: wrapWidth);
  }
  if (pipeIntoFile) {
    // todo 写日志文件
  }
}
