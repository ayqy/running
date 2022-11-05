import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';


class AudioUtil {
  static AudioHandler? _audioHandler;

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
  // static final _item = MediaItem(
  //   id: 'http://cdn.ayqy.net/music%2F%E8%8A%B1%E3%81%9F%E3%82%93%20-%20%E5%8D%83%E6%9C%AC%E6%A1%9C.mp3',
  //   album: "百狐千樂",
  //   title: "千本桜",
  //   artist: "花たん",
  //   duration: const Duration(milliseconds: 243000),
  //   artUri: Uri.parse('http://cdn.ayqy.net/music/%E5%8D%83%E6%9C%AC%E6%A1%9C.jpg'),
  // );

  static final _item = MediaItem(
    id: 'http://cdn.ayqy.net/music/%E8%A5%BF%E5%AE%89%E7%88%B1%E6%83%85%E6%95%85%E4%BA%8B.mp4',
    album: "没有人比我更爱你",
    title: "西安爱情故事",
    artist: "王筝",
    duration: const Duration(milliseconds: 232000),
    artUri: Uri.parse('http://cdn.ayqy.net/music/%E7%8E%8B%E7%AD%9D.jpeg'),
  );

  final _player = AudioPlayer();

  /// Initialise our audio handler.
  AudioPlayerHandler() {
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

