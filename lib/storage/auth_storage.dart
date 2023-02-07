import 'dart:async';
import 'package:azure_ad_oauth/model/token.dart';
import 'i_storage.dart';
import 'dart:convert' as convert;

class AuthStorage {
  final IStorage _storage = IStorage();
  String identifier;

  ///
  AuthStorage({this.identifier = 'Token'});

  ///
  Future<void> saveTokenToStorage(Token? token) async {
    var data = Token.toJsonMap(token);
    var json = convert.jsonEncode(data);
    await _storage.write(key: identifier, value: json);
  }

  ///
  Future<T?> loadTokenFromStorageToCache<T extends Token>() async {
    var json = await _storage.read(key: identifier);
    if (json == null) return null;
    try {
      var data = convert.jsonDecode(json);
      return _getTokenFromMap<T>(data) as FutureOr<T?>;
    } catch (exception) {
      return null;
    }
  }

  ///
  Token _getTokenFromMap<T extends Token>(Map<String, dynamic>? data) =>
      Token.fromJson(data);

  ///
  Future<void> clear() async {
    await _storage.delete(key: identifier);
  }
}
