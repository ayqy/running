import 'package:volume_controller/volume_controller.dart';
import 'package:flutter_mute/flutter_mute.dart';

class Volume {
  static final volumeController = VolumeController();

  static Future<bool> isMute() async {
    RingerMode ringerMode = await FlutterMute.getRingerMode();
    return ringerMode != RingerMode.Normal;
  }

  ///获取系统音量
  static Future<double> getVolume() async {
    return volumeController.getVolume();
  }

  ///设置系统音量
  static setVolume(double volume) async {
    volumeController.setVolume(volume);
  }

  ///监测系统音量
  static onVolumeChanged(Function callback) {
    volumeController.listener((double volume) {
      callback(volume);
    });
  }
}
