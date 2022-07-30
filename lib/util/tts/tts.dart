import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_tts/flutter_tts.dart';
import 'volume.dart';
import '../toast.dart';
import '../log.dart';

enum TtsState { playing, stopped, paused, continued }

class TTS {
  static late FlutterTts flutterTts;
  // [ja-JP, zh-HK, cs-CZ, nl-BE, th-TH, ar-SA, pl-PL, it-IT, en-AU, en-US, de-DE, nl-NL, ru-RU, pt-PT, tr-TR, hi-IN, zh-TW, fr-CA, el-GR, he-IL, es-MX, ro-RO, sv-SE, fi-FI, zh-CN, en-GB, hu-HU, pt-BR, en-IE, fr-FR, da-DK, en-IN, en-ZA, id-ID, no-NO, ko-KR, es-ES, sk-SK]
  static String? language = 'zh-CN';
  static String? engine;
  static double volume = 1.0;
  static double pitch = 1.0;
  static double rate = 0.55;
  static bool isCurrentLanguageInstalled = false;

  static String? _newVoiceText;

  static TtsState ttsState = TtsState.stopped;

  static get isPlaying => ttsState == TtsState.playing;
  static get isStopped => ttsState == TtsState.stopped;
  static get isPaused => ttsState == TtsState.paused;
  static get isContinued => ttsState == TtsState.continued;

  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isWeb => kIsWeb;

  static init() async {
    bool isMute = await Volume.isMute();
    if (isMute) {
      toast('设备静音，无法开启语音播报');
    }
    else {
      double volume = await Volume.getVolume();
      if (volume < 0.2) {
        toast('音量过低，请调高');
      }
    }

    flutterTts = FlutterTts();

    await _setAwaitOptions();

    if (isAndroid) {
      await _getDefaultEngine();
    }

    if (isIOS) {
      await flutterTts.setSharedInstance(true);
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }

    flutterTts.setStartHandler(() {
      log("Playing");
      ttsState = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      log("Complete");
      ttsState = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      log("Cancel");
      ttsState = TtsState.stopped;
    });

    if (isWeb || isIOS || isWindows) {
      flutterTts.setPauseHandler(() {
        log("Paused");
        ttsState = TtsState.paused;
      });

      flutterTts.setContinueHandler(() {
        log("Continued");
        ttsState = TtsState.continued;
      });
    }

    flutterTts.setErrorHandler((msg) {
      log("error: $msg");
      ttsState = TtsState.stopped;
    });
  }

  static Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      log(engine);
    }
  }

  static Future<void> wait() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  static Future<void> speak(String text, [Map<String, Object>? options]) {
    _newVoiceText = text;
    return _speak(options);
  }

  static Future _speak([Map<String, Object>? options]) async {
    double volume = options?['volume'] as double? ?? TTS.volume;
    double rate = options?['rate'] as double? ?? TTS.rate;
    double pitch = options?['pitch'] as double? ?? TTS.pitch;
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  static Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  static void stop() {
    _stop();
  }

  static Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      ttsState = TtsState.stopped;
    }
  }

  static void pause() {
    _pause();
  }

  static Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) {
      ttsState = TtsState.paused;
    }
  }

  static void dispose() {
    flutterTts.stop();
  }
}
