import 'package:date_format/date_format.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:running/const/theme.dart';
import 'package:running/widget/custom_app_bar.dart';

import 'const/ui.dart';
import 'util/account.dart';
import 'util/dialog.dart';
import 'api/account.dart';
import 'const/icon.dart';


class Login extends StatefulWidget {
  const Login({Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

enum FormType {
  login,
  signup
}
class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map formData = {};
  final nicknameController = TextEditingController();
  final usernameController = TextEditingController(text: AccountUtil.getUsername(true));
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  FormType formType = FormType.login;

  _onLoginPressed() async {
    Map? formData = _getFormData();
    if (formData != null) {
      EasyLoading.show(status: '登录中...');
      var result = await AccountAPI.login(formData);
      EasyLoading.dismiss();
      if (result != false) {
        EasyLoading.showSuccess('登录成功');
        // 无意义，直接为了避免async方法里使用context的时机警告
        if (!mounted) return;
        Navigator.of(context).pop();
      }
      else {
        EasyLoading.showError('登录失败，请重试～');
      }
    }
  }

  _onSignupTextLinkPressed() {
    setState(() {
      formType = FormType.signup;
      nicknameController.clear();
      usernameController.clear();
      passwordController.clear();
    });
  }

  _onSignupPressed() async {
    Map? formData = _getFormData();
    if (formData != null) {
      var result = await AccountAPI.signup(formData);
      if (result != false) {
        EasyLoading.showSuccess('注册成功，快登录吧');
        setState(() {
          formType = FormType.login;
          // 保留账号，清空密码
          usernameController.text = formData['username'];
          nicknameController.clear();
          passwordController.clear();
        });
      }
      else {
        EasyLoading.showError('注册失败，请重试～');
      }
    }
  }

  _getFormData() {
    bool valid = _formKey.currentState!.validate();
    if (valid) {
      _formKey.currentState!.save();
      return formData;
    }
    return null;
  }

  _onForgetPressed() {
    MyDialog.alert(context, '请邮件联系 nwujiajie@163.com 重置密码');
  }

  _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  @override
  dispose() {
    super.dispose();
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "登录",
      ),
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            color: ThemeColors.backgroundColor,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: const Image(
                          image: AssetImage('images/icon.jpeg'),
                          width: 80,
                        ),
                      ),
                      SizedBox(height: formType == FormType.login ? 30 : 15),
                      Visibility(
                        visible: formType == FormType.signup,
                        child: TextFormField(
                          maxLength: 7,
                          decoration: InputDecoration(
                            hintText: '昵称',
                            icon: Icon(Icons.person, size: 20, color: ThemeColors.regularTextColor),
                            hintStyle: TextStyle(color: ThemeColors.regularTextColor),
                          ),
                          style: TextStyle(color: ThemeColors.valueTextColor),
                          onSaved: (value) {
                            formData['nickname'] = value;
                          },
                          validator: (value) {
                            if (value?.isEmpty ?? false) {
                              return '昵称不能为空';
                            }
                            return null;
                          },
                          controller: nicknameController,
                        ),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9@_\\-\\.]')),
                        ],
                        decoration: InputDecoration(
                          hintText: '手机号或邮箱',
                          icon: Icon(Icons.phone_android, size: 20, color: ThemeColors.regularTextColor),
                          hintStyle: TextStyle(color: ThemeColors.regularTextColor),
                        ),
                        style: TextStyle(color: ThemeColors.valueTextColor),
                        onSaved: (value) {
                          formData['username'] = value;
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? false) {
                            return '手机号或邮箱不能为空';
                          }
                          RegExp reg = RegExp(r'^\d{11}$');
                          if (!reg.hasMatch(value!) && !EmailValidator.validate(value)) {
                            return '手机号或邮箱不存在';
                          }
                          return null;
                        },
                        controller: usernameController,
                      ),
                      Stack(
                        children: [
                          TextFormField(
                            obscureText: formType == FormType.login && !isPasswordVisible,
                            keyboardType: TextInputType.visiblePassword,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp("^[\u0000-\u007F]+\$")),
                            ],
                            decoration: InputDecoration(
                              hintText: '密码',
                              icon: Icon(Icons.lock, size: 20, color: ThemeColors.regularTextColor),
                              hintStyle: TextStyle(color: ThemeColors.regularTextColor),
                            ),
                            style: TextStyle(color: ThemeColors.valueTextColor),
                            onSaved: (value) {
                              formData['password'] = value;
                            },
                            validator: (value) {
                              if (value?.isEmpty ?? false) {
                                return '密码不能为空';
                              }
                              if (value!.length > 16) {
                                return '密码不能超出16位';
                              }
                              return null;
                            },
                            controller: passwordController,
                          ),
                          Visibility(
                            visible: formType == FormType.login,
                            child: Positioned(
                              top: 0,
                              right: -10,
                              child: SizedBox(
                                child: IconButton(
                                  icon: Icon(isPasswordVisible ? MyIcon.eye : MyIcon.eye_off),
                                  padding: const EdgeInsets.all(0),
                                  color: const Color(0xff999999),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: formType == FormType.login,
                        child: Row(
                          children: [
                            TextButton(onPressed: _onSignupTextLinkPressed, child: const Text('还没有账号？注册一个')),
                            const Spacer(
                              flex: 1,
                            ),
                            TextButton(onPressed: _onForgetPressed, child: const Text(
                              '忘记密码',
                              style: TextStyle(
                                color: Color(0xff444444),
                              ),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeColors.selectedColor, // 使用主题配置的颜色
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: formType == FormType.login ? _onLoginPressed : _onSignupPressed,
                        child: Text(
                            formType == FormType.login ? '登录' : '立即注册',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}