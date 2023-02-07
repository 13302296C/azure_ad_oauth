import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IStorage {
  Future<void> delete({required String key}) async {
    await const FlutterSecureStorage().delete(key: key);
  }

  Future<String?> read({required String key}) async {
    return const FlutterSecureStorage().read(key: key);
  }

  Future<void> write({required String key, required String value}) async {
    await const FlutterSecureStorage().write(key: key, value: value);
  }
}
