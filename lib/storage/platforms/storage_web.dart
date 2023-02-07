// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

class IStorage {
  Future<void> delete({required String key}) async {
    window.localStorage.remove(key);
  }

  Future<String?> read({required String key}) async {
    return window.localStorage[key];
  }

  Future<void> write({required String key, required String value}) async {
    window.localStorage[key] = value;
  }
}
