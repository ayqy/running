import 'package:flutter/material.dart';

import 'const/ui.dart';
import 'util/log.dart';


class Settings extends StatefulWidget {
  const Settings({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsState();
  }
}

class _SettingsState extends State<Settings> {
  Map settings = {};

  _onItemPressed(int? value) {
    log('click$value');
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCard(List items) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Row(
              children: [
                Text(item['key'] ?? ''),
                const Expanded(child: SizedBox()),
                Text(item['text'] ?? '', style: const TextStyle(color: Colors.grey)),
                // const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                Radio(
                  value: item['value'],
                  groupValue: item['selected'],
                  onChanged: item['action'],
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
      appBar: AppBar(
        toolbarHeight: UIConsts.APPBAR_TOOLBAR_HEIGHT,
        title: const Text("设置"),
        flexibleSpace: UIConsts.APPBAR_FLEXIBLE_SPACE,
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        color: const Color(0xfff6f7f7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('音乐'),
            _buildCard([{
              'key': '清新舒缓',
              'text': '西安爱情故事 - 王筝',
              'value': 1,
              'selected': settings['selected_music'] ?? 0,
              'action': (_) {
                setState(() {
                  settings['selected_music'] = 1;
                });
              }
            }, {
              'key': '燃烧战歌',
              'text': '千本桜 - 花たん',
              'value': 2,
              'selected': settings['selected_music'] ?? 0,
              'action': (_) {
                setState(() {
                  settings['selected_music'] = 2;
                });
              }
            }]),
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
