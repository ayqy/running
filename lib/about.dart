import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'const/ui.dart';


class About extends StatefulWidget {
  const About({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AboutState();
  }
}

class _AboutState extends State<About> {
  PackageInfo? packageInfo;

  @override
  initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      setState(() {
        packageInfo = info;
      });
    });
  }

  Widget _buildCard(List pairs) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Column(
        children: pairs.map((pair) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Text(pair['key'] ?? ''),
                const Expanded(child: SizedBox()),
                Text(pair['value'] ?? '', style: const TextStyle(color: Colors.grey)),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
      appBar: AppBar(
        toolbarHeight: UIConsts.APPBAR_TOOLBAR_HEIGHT,
        title: const Text("关于"),
        flexibleSpace: UIConsts.APPBAR_FLEXIBLE_SPACE,
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        color: const Color(0xfff6f7f7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const Image(
                  image: AssetImage('images/icon.png'),
                  width: 60,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                version,
                style: const TextStyle(
                  color: Color(0xff333333),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildCard([{
              'key': '官方邮箱',
              'value': 'nwujiajie@163.com',
            }, {
              'key': '微信公众号',
              'value': '前端问问',
            }]),
            const Expanded(child: SizedBox()),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                  'Copyright©2022 黯羽轻扬. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff999999),
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
