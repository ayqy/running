import 'package:xxtea/xxtea.dart';

import '../const/secret_config.dart';

// 加密
String encrypt(String str) {
  String key = SecretConfig.get('CRYPTO_KEY');
  String? encrypted = xxtea.encryptToString(str, key);
  return encrypted ?? '';
}

// 解密
String decrypt(String str) {
  String key = SecretConfig.get('CRYPTO_KEY');
  String? decrypted = xxtea.decryptToString(str, key);
  return decrypted ?? '';
}
