String? _token;

Future<void> saveToken(String? token) async {
  if (token != null && token.isNotEmpty) {
    _token = token;
  }
}

Future<String?> getToken() async => _token;

Future<void> deleteToken() async {
  _token = null;
}
