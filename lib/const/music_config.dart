import 'package:audio_service/audio_service.dart';

import '../util/storage.dart';

class MusicConfig {
  static const selectedMusicKey = 'selected_music';
  static int? _selectedMusic;

  static Future<int> getSelectedMusic() async {
    if (_selectedMusic != null) {
      return _selectedMusic!;
    }
    String value = await Storage.get(selectedMusicKey);
    _selectedMusic = value.isNotEmpty ? int.parse(value) : 0;
    return _selectedMusic!;
  }

  static Future<void> setSelectedMusic(int index) async {
    _selectedMusic = index;
    await Storage.set(selectedMusicKey, '$index');
  }
  static final List<MediaItem> musicList = [
    MediaItem(
      id: 'https://node.ayqy.net/music/slow.mp3',
      album: "清新舒缓",
      title: "草原的夜宁静而安详",
      artist: "Snowflake",
      duration: const Duration(milliseconds: 265000),
      artUri: Uri.parse('https://node.ayqy.net/music/music.png'),
    ),
    MediaItem(
      id: 'https://node.ayqy.net/music/quick.mp3',
      album: "超燃运动",
      title: "在天空中翱翔",
      artist: "Levihica",
      duration: const Duration(milliseconds: 314000),
      artUri: Uri.parse('https://node.ayqy.net/music/music.png'),
    ),
  ];

  static MediaItem getMusic(int index) {
    if (index < 0 || index >= musicList.length) {
      return musicList[0];
    }
    return musicList[index];
  }
}