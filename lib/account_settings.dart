import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:running/widget/custom_app_bar.dart';
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
import 'const/icon.dart';
import 'const/theme.dart';


typedef OnPickImageCallback = void Function(double? maxWidth, double? maxHeight, int? quality);

class AccountSettings extends StatefulWidget {
  const AccountSettings({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AccountSettingsState();
  }
}

class _AccountSettingsState extends State<AccountSettings> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoggedIn = AccountUtil.isLoggedIn();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  dynamic _pickImageError;
  String _nickname = '';

  _onLogoutPressed() async {
    await AccountAPI.logout();
    // 无论服务成功失败都删除本地token
    await AccountUtil.removeToken();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  _onDeleteAccountPressed() {
    MyDialog.confirm(context, const Text(
      '注销账号后，您的所有数据将被永久删除且无法恢复。\n确定要注销账号吗？',
      style: TextStyle(fontSize: 16),
    ), (close) async {
      EasyLoading.show(status: '注销中...');
      var result = await AccountAPI.remove();
      if (result != false) {
        await AccountUtil.removeToken();
        EasyLoading.showSuccess('账号已注销');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        EasyLoading.showError('注销失败，请重试');
      }
      close();
    }, title: '注销账号');
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
        MyDialog.confirm(context, _previewImages(), (close) async {
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
              close();
              return;
            }
          }
          EasyLoading.showError('头像上传失败了，再试试吧');
          close();
        }, title: '上传头像');
      }
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  _updateNickname() {
    MyDialog.confirm(context, _buildNicknameForm(), (close) async {
      bool valid = _formKey.currentState?.validate() ?? false;
      if (!valid) {
        return;
      }
      _formKey.currentState?.save();
      EasyLoading.showProgress(0);
      // 调用两次，暂时绕过bug https://github.com/nslogx/flutter_easyloading/issues/18
      await Future.delayed(const Duration(milliseconds: 50));
      EasyLoading.showProgress(0.1);
      var updateResult = await AccountAPI.update({ 'nickname': _nickname });
      if (updateResult != false) {
        EasyLoading.showProgress(0.9);
        await AccountUtil.fetch();
        EasyLoading.showSuccess('修改成功');
        // 刷一把，重新获取昵称
        setState(() {});
        close();
        return;
      }
      EasyLoading.showError('昵称修改失败了，再试试吧');
      close();
    }, title: '修改昵称');
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

  Widget _buildNicknameForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            keyboardType: TextInputType.text,
            initialValue: AccountUtil.getNickname(),
            decoration: const InputDecoration(
              hintText: '想个新昵称',
              icon: Icon(MyIcon.feather, size: 20),
            ),
            style: TextStyle(color: ThemeColors.valueTextColor),
            onSaved: (value) {
              _nickname = value ?? '';
            },
            validator: (value) {
              if (value?.isEmpty ?? false) {
                return '昵称不能为空';
              }
              return null;
            },
          ),
        ],
      )
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
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
        color: ThemeColors.cardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: items.map((item) {
          Widget valuePart;
          if (item['value'] is Widget) {
            valuePart = item['value'];
          }
          else {
            valuePart = Text(item['value'] ?? '', style: TextStyle(color: ThemeColors.regularTextColor));
          }
          return InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onTap: () {
              if (item['onTap'] != null) {
                item['onTap']();
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
              child: Row(
                children: [
                  Text(item['key'] ?? '', style: TextStyle(color: ThemeColors.valueTextColor)),
                  const Expanded(child: SizedBox()),
                  valuePart,
                  Icon(Icons.arrow_forward_ios, size: 16, color: ThemeColors.regularTextColor),
                ],
              ),
            ),
          );
        }).toList(),
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
      appBar: CustomAppBar(
        title: "账号设置",
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        color: ThemeColors.backgroundColor,
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
              'onTap': _updateNickname,
            }]),
            _buildSectionTitle('账号设置'),
            _buildCard([{
              'key': '账号',
              'value': username,
            }, {
              'key': '修改密码',
              'value': '',
            }, {
              'key': '注销账号',
              'value': Text(
                '注销账号',
                style: TextStyle(
                  color: ThemeColors.selectedTheme == ThemeType.dark ? 
                      const Color(0xFFFF5252) : const Color(0x99ff0000),
                ),
              ),
              'onTap': _onDeleteAccountPressed,
            }]),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onLogoutPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.cardColor,
                shadowColor: ThemeColors.dividerColor,
                minimumSize: const Size.fromHeight(45),
              ),
              child: Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 16,
                  color: ThemeColors.selectedTheme == ThemeType.dark ? 
                      const Color(0xFFFF5252) : const Color(0x99ff0000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
