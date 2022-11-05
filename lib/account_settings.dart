import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';

import 'api/avatar.dart';
import 'const/ui.dart';
import 'util/account.dart';
import 'api/account.dart';
import 'util/log.dart';
import 'util/dialog.dart';
import 'util/toast.dart';


typedef OnPickImageCallback = void Function(double? maxWidth, double? maxHeight, int? quality);

class AccountSettings extends StatefulWidget {
  const AccountSettings({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AccountSettingsState();
  }
}

class _AccountSettingsState extends State<AccountSettings> {
  bool isLoggedIn = AccountUtil.isLoggedIn();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  dynamic _pickImageError;

  _onLogoutPressed() async {
    await AccountAPI.logout();
    // 无论服务成功失败都删除本地token
    await AccountUtil.removeToken();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _setImageFileFromFile(XFile? value) {
    _imageFile = value;
  }

  _pickAvatar() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 75,
      );
      setState(() {
        _setImageFileFromFile(pickedFile);
      });
      if (_imageFile != null) {
        if (!mounted) return;
        MyDialog.confirm(context, _previewImages(), () async {
          EasyLoading.showProgress(0, status: '头像制作中...');
          // 调用两次，暂时绕过bug https://github.com/nslogx/flutter_easyloading/issues/185
          await Future.delayed(const Duration(milliseconds: 50));
          EasyLoading.showProgress(0.1, status: '头像制作中...');
          var uploadResult = await AvatarAPI.create(File(_imageFile!.path));
          if (uploadResult != false) {
            EasyLoading.showProgress(0.4, status: '开始上传...');
            String avatarUrl = uploadResult['url'];
            var updateResult = await AccountAPI.update({ 'avatarUrl': avatarUrl });
            if (updateResult != false) {
              EasyLoading.showProgress(0.9, status: '马上就好...');
              await AccountUtil.fetch();
              EasyLoading.showSuccess('头像上传成功');
              // 刷一把，重新获取头像
              setState(() {});
              return;
            }
          }
          EasyLoading.showError('头像上传失败了，再试试吧');
        }, title: '上传头像');
      }
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  Widget _previewImages() {
    if (_imageFile != null) {
      return Semantics(
        label: 'image_picker_example_picked_image',
        child: Container(
          child: kIsWeb
            ? Image.network(_imageFile!.path)
            : Image.file(File(_imageFile!.path)),
        ),
      );
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
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
    return Material(
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: items.map((item) {
            Widget valuePart;
            if (item['value'] is Widget) {
              valuePart = item['value'];
            }
            else {
              valuePart = Text(item['value'] ?? '', style: const TextStyle(color: Colors.grey));
            }
            return InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onTap: () {
                if (item['onTap'] != null) {
                  item['onTap']();
                }
                log('click');
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
                child: Row(
                  children: [
                    Text(item['key'] ?? ''),
                    const Expanded(child: SizedBox()),
                    valuePart,
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  dispose() {
    super.dispose();
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    String nickname = AccountUtil.getNickname();
    String username = AccountUtil.getUsername();
    String avatarUrl = AccountUtil.getAvatarUrl();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: UIConsts.APPBAR_TOOLBAR_HEIGHT,
        title: const Text("账号设置"),
        flexibleSpace: UIConsts.APPBAR_FLEXIBLE_SPACE,
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        color: const Color(0xfff6f7f7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('个人资料'),
            _buildCard([{
              'key': '头像',
              'value': avatarUrl.isNotEmpty ? SizedBox(
                width: 32,
                height: 32,
                child: CircularProfileAvatar(avatarUrl),
              ) : '',
              'onTap': _pickAvatar,
            }, {
              'key': '昵称',
              'value': nickname,
            }]),
            _buildSectionTitle('账号设置'),
            _buildCard([{
              'key': '账号',
              'value': username,
            }, {
              'key': '修改密码',
              'value': '',
            }]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onLogoutPressed,
              style: ElevatedButton.styleFrom(
                primary: const Color(0xfffdfdfd),
                shadowColor: const Color(0x33e0e0e0),
                minimumSize: const Size.fromHeight(45),
              ),
              child: const Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0x99ff0000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
