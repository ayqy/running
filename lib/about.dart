import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:running/util/account.dart';
import 'package:running/util/device.dart';
import 'package:running/util/dialog.dart';
import 'package:running/widget/custom_app_bar.dart';

import 'const/ui.dart';
import 'util/after.dart';
import 'const/theme.dart';


class About extends StatefulWidget {
  const About({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AboutState();
  }
}

class _AboutState extends State<About> {
  PackageInfo? packageInfo;
  bool showHiddenInfo = false;

  @override
  initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      setState(() {
        packageInfo = info;
      });
    });
  }

  _openHiddenInfo() {
    setState(() {
      String content = [
        "diu=${DeviceUtil.getId()}",
        "uid=${AccountUtil.getUid()}",
        "token=${AccountUtil.getToken()}"
      ].join('\n');
      MyDialog.alert(context, content, title: '关于', buttonText: '复制', onPressed: () {
        Clipboard.setData(ClipboardData(text: content));
      });
    });
  }

  Widget _buildCard(List pairs) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: ThemeColors.cardColor,
      ),
      child: Column(
        children: pairs.map((pair) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Text(pair['key'] ?? '', style: TextStyle(color: ThemeColors.regularTextColor)),
                const Expanded(child: SizedBox()),
                Text(pair['value'] ?? '', style: TextStyle(color: ThemeColors.valueTextColor)),
                Icon(Icons.arrow_forward_ios, size: 16, color: ThemeColors.regularTextColor),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String version = packageInfo != null ? "当前版本：${packageInfo!.version}.${packageInfo!.buildNumber}" : '';

    return Scaffold(
      appBar: CustomAppBar(
        title: "关于",
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        color: ThemeColors.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: IconButton(
                  icon: const Image(
                    image: AssetImage('images/icon.jpeg'),
                    width: 60,
                  ),
                  onPressed: after(3, _openHiddenInfo),
                )
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                version,
                style: TextStyle(
                  color: ThemeColors.valueTextColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildCard([{
              'key': '官方邮箱',
              'value': 'nwujiajie@163.com',
            }, {
              'key': '微信公众号',
              'value': '老哥职说',
            }]),
            const Expanded(child: SizedBox()),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                  'Copyright©2022 贾杰. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeColors.regularTextColor,
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
