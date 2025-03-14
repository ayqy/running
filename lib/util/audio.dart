import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../const/music_config.dart';
import '../const/storage_key.dart';
import 'storage.dart';

class AudioUtil {
  static AudioHandler? _audioHandler;

  static AudioHandler? get audioHandler => _audioHandler;

  static Future<AudioHandler> init() async {
    _audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'net.ayqy.running.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
    return _audioHandler!;
  }

  static Future<void>? play() {
    return _audioHandler?.play();
  }

  static Future<void>? stop() {
    return _audioHandler?.stop();
  }

  static Future<void>? pause() {
    return _audioHandler?.pause();
  }
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  static late MediaItem _item;

  final _player = AudioPlayer();

  /// Initialise our audio handler.
  AudioPlayerHandler() {
    // Get selected music index from storage
    MusicConfig.getSelectedMusic().then((selectedIndex) {
      _item = MusicConfig.getMusic(selectedIndex);
      // So that our clients (the Flutter UI and the system notification) know
      // what state to display, here we set up our audio handler to broadcast all
      // playback state changes as they happen via playbackState...
      _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
      // ... and also the current media item via mediaItem.
      mediaItem.add(_item);

      // Load the player.
      _player.setAudioSource(AudioSource.uri(Uri.parse(_item.id)));
      // loop
      _player.setLoopMode(LoopMode.all);
    });
  }

  /// Update current playing music
  Future<void> updateMusic(int selectedIndex) async {
    _item = MusicConfig.getMusic(selectedIndex);
    mediaItem.add(_item);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(_item.id)));
    await _player.setLoopMode(LoopMode.all);
  }

  // In this simple example, we handle only 4 actions: play, pause, seek and
  // stop. Any button press from the Flutter UI, notification, lock screen or
  // headset will be routed through to these 4 methods so that you can handle
  // your audio playback logic in one place.

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  /// Transform a just_audio event into an audio_service state.
  ///
  /// This method is used from the constructor. Every event received from the
  /// just_audio player will be transformed into an audio_service state so that
  /// it can be broadcast to audio_service clients.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

