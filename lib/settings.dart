import 'package:flutter/material.dart';

import 'const/ui.dart';
import 'const/music_config.dart';
import 'util/log.dart';
import 'util/audio.dart';
import 'util/storage.dart';
import 'const/theme.dart';
import 'widget/custom_app_bar.dart';
import 'util/toast.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsState();
  }
}

class _SettingsState extends State<Settings> {
  Map settings = {};
  int? selectedMusic;
  ThemeType? selectedTheme;

  @override
  void initState() {
    super.initState();
    MusicConfig.getSelectedMusic().then((value) {
      setState(() {
        selectedMusic = value;
      });
      MusicConfig.setSelectedMusic(value);
      // 更新正在播放的音乐
      if (AudioUtil.audioHandler is AudioPlayerHandler) {
        (AudioUtil.audioHandler as AudioPlayerHandler).updateMusic(value);
      }
    });
    ThemeColors.getCurrentTheme().then((value) {
      setState(() {
        selectedTheme = value;
      });
    });
  }

  _onItemPressed(int? value) {
    log('click$value');
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        title,
        style: TextStyle(
          color: ThemeColors.regularTextColor,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCard(List items) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: ThemeColors.cardColor,
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Row(
              children: [
                Text(item['key'] ?? '', style: TextStyle(color: ThemeColors.valueTextColor)),
                const Expanded(child: SizedBox()),
                Text(item['text'] ?? '', style: TextStyle(color: ThemeColors.regularTextColor)),
                Radio(
                  value: item['value'],
                  groupValue: item['selected'],
                  onChanged: item['action'],
                  activeColor: ThemeColors.selectedColor
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "设置",
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        color: ThemeColors.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('主题'),
            _buildCard([{
              'key': '冷酷黑',
              'text': '',
              'value': ThemeType.dark,
              'selected': selectedTheme ?? ThemeType.dark,
              'action': (_) async {
                setState(() {
                  selectedTheme = ThemeType.dark;
                });
                await ThemeColors.setCurrentTheme(ThemeType.dark);
                toast('已切换至冷酷黑');
              }
            }, {
              'key': '活力绿',
              'text': '',
              'value': ThemeType.light,
              'selected': selectedTheme ?? ThemeType.dark,
              'action': (_) async {
                setState(() {
                  selectedTheme = ThemeType.light;
                });
                await ThemeColors.setCurrentTheme(ThemeType.light);
                toast('已切换至活力绿');
              }
            }]),
            _buildSectionTitle('音乐'),
            _buildCard(MusicConfig.musicList.asMap().entries.map((entry) => {
              'key': entry.value.album,
              'text': '${entry.value.title} - ${entry.value.artist}',
              'value': entry.key,
              'selected': selectedMusic ?? 0,
              'action': (_) async {
                setState(() {
                  selectedMusic = entry.key;
                });
                await MusicConfig.setSelectedMusic(entry.key);
                // 更新正在播放的音乐
                if (AudioUtil.audioHandler is AudioPlayerHandler) {
                  (AudioUtil.audioHandler as AudioPlayerHandler).updateMusic(entry.key);
                }
              }
            }).toList()),
            _buildSectionTitle('播报'),
            _buildCard([{
              'key': '按公里数',
              'text': '',
              'value': 1,
              'selected': settings['tts_mode'] ?? 0,
              'action': (_) {
                setState(() {
                  settings['tts_mode'] = 1;
                });
              }
            }, {
              'key': '按时间',
              'text': '',
              'value': 2,
              'selected': settings['tts_mode'] ?? 0,
              'action': (_) {
                setState(() {
                  settings['tts_mode'] = 2;
                });
              }
            }]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
