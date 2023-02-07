class IStorage {
  IStorage() {
    throw Exception('Unsupported platform');
  }

  Future<void> write({required String key, required String value}) async {
    throw Exception('Unsupported platform');
  }

  Future<String?> read({required String key}) async {
    throw Exception('Unsupported platform');
  }

  Future<void> delete({required String key}) async {
    throw Exception('Unsupported platform');
  }
}
