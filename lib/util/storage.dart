import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  // Create storage
  static const storage = FlutterSecureStorage();

  static Future<String> get(key) async {
    String? value = await storage.read(key: key);
    return value ?? '';
  }

  static Future<Map<String, String>> getAll() {
    return storage.readAll();
  }

  static Future<void> remove(key) {
    return storage.delete(key: key);
  }

  static Future<void> removeAll() {
    return storage.deleteAll();
  }

  static Future<void> set(key, value) {
    return storage.write(key: key, value: value);
  }
}
