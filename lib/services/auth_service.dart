import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'storage_service.dart';

class AuthService {
  AuthService();

  Future login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String? token =
            data['access_token']?.toString() ?? data['token']?.toString();

        if (token != null && token.isNotEmpty) {
          await StorageService.saveToken(token);
        }
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              data['detail']?.toString() ??
              'Login failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('AuthService login catch error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
