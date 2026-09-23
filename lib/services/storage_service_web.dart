import 'package:web/web.dart' as web;

const String _tokenKey = 'jwt_token';

Future<void> saveToken(String? token) async {
  if (token != null && token.isNotEmpty) {
    web.window.localStorage.setItem(_tokenKey, token);
  }
}

Future<String?> getToken() async => web.window.localStorage.getItem(_tokenKey);

Future<void> deleteToken() async {
  web.window.localStorage.removeItem(_tokenKey);
}
