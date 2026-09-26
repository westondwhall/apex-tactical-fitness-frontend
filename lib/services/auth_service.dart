import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'storage_service.dart';

class AuthService {
  AuthService();

  Future<void> logout() async {
    await StorageService.deleteToken();
  }

  Future<Map<String, dynamic>> deleteUserAccount() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/auth/account'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        return {'success': false, 'error': 'Account deletion failed'};
      }

      await StorageService.deleteToken();
      return {'success': true};
    } catch (e) {
      debugPrint('AuthService account deletion error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> reauthenticateAndDeleteUserAccount(
    String email,
    String password,
  ) async {
    final authResult = await login(email, password);
    if (authResult['success'] != true) {
      return {
        'success': false,
        'error': authResult['error'] ?? 'Reauthentication failed',
      };
    }

    return deleteUserAccount();
  }

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
