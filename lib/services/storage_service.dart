import 'storage_service_platform.dart'
    if (dart.library.js_interop) 'storage_service_web.dart'
    as platform;

class StorageService {
  static Future<void> saveToken(String? token) async {
    await platform.saveToken(token);
  }

  static Future<String?> getToken() async {
    return platform.getToken();
  }

  static Future<void> deleteToken() async {
    await platform.deleteToken();
  }
}
