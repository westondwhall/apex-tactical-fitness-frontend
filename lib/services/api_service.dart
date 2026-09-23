import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  ApiService();

  Future<dynamic> sendMessage(String message) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/chat'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? data['message'] ?? 'No response';
    }

    try {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['detail'] ?? 'Failed to communicate with Apex coach',
      );
    } catch (_) {
      throw Exception('Failed to communicate with Apex coach');
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/chat-history'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = data is Map ? data['messages'] : null;
      if (messages is List) {
        return messages
            .whereType<Map>()
            .map((message) => Map<String, dynamic>.from(message))
            .toList();
      }
      return [];
    }

    throw Exception('Failed to load chat history');
  }

  Future<void> deleteChatMessage(String messageId) async {
    final token = await StorageService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/chat-messages/$messageId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete chat message');
    }
  }

  Future<dynamic> getProfile() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/profile'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to load profile');
    } catch (_) {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> postProfile(Map<String, dynamic> profileData) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/profile'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to save profile');
      } catch (_) {
        throw Exception('Failed to save profile');
      }
    }
  }

  Future<dynamic> generateWorkoutPlan(
    String targetAgency,
    int timelineWeeks,
  ) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/generate-plan'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'target_agency': targetAgency,
        'timeline_weeks': timelineWeeks,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['workout_plan'] ?? data;
    }

    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to generate workout plan');
    } catch (_) {
      throw Exception('Failed to generate workout plan');
    }
  }

  Future<Map<String, dynamic>> generateProgram(String agency, int weeks) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/generate-plan'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'target_agency': agency, 'timeline_weeks': weeks}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {'workout_plan': decoded};
    }

    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to generate program');
    } catch (_) {
      throw Exception('Failed to generate program');
    }
  }

  Future<void> postWorkoutLog(Map<String, dynamic> logData) async {
    final token = await StorageService.getToken();
    final payload = Map<String, dynamic>.from(logData);
    // The workout_logs table stores the completion time as timestamp, not date.
    final date = payload.remove('date');
    if (!payload.containsKey('timestamp') && date != null) {
      payload['timestamp'] = DateTime.tryParse(date.toString())
          ?.toIso8601String();
    }
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/workout-logs'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Failed to sync workout log to server';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData['detail'] != null) {
          message = errorData['detail'].toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) message = response.body;
      }
      throw Exception(message);
    }
  }

  Future<void> saveWorkoutPlan(
    String targetAgency,
    int timelineWeeks,
    String planText,
  ) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/save-plan'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'target_agency': targetAgency,
        'timeline_weeks': timelineWeeks,
        'plan_text': planText,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to save workout plan');
      } catch (_) {
        throw Exception('Failed to save workout plan');
      }
    }
  }

  Future<void> deleteWorkoutPlan(String id) async {
    final token = await StorageService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/workout-plans/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to delete workout plan');
      } catch (_) {
        throw Exception(
          'Failed to delete workout plan: ${response.statusCode}',
        );
      }
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/analytics'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw Exception('Invalid analytics response');
    }

    try {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to load analytics');
    } catch (_) {
      throw Exception('Failed to load analytics');
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogbook() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/workout-logbook'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final logs = decoded is Map ? decoded['logs'] : decoded;
      if (logs is List) {
        return logs
            .whereType<Map>()
            .map((log) => Map<String, dynamic>.from(log))
            .toList();
      }
      return [];
    }

    String message = 'Failed to load workout logbook';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map && errorData['detail'] != null) {
        message = errorData['detail'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  Future<List<dynamic>> getWorkoutHistory() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/workout-history'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<dynamic>();
      } else if (decoded is Map && decoded['history'] is List) {
        return List.from(decoded['history'] as List).cast<dynamic>();
      }
      return [];
    }

    String message = 'Failed to load workout history';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map && errorData['detail'] != null) {
        message = errorData['detail'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  Future<void> deleteWorkoutLog(String id) async {
    final token = await StorageService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/workout-logs/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      String message = 'Failed to delete workout log';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData['detail'] != null) {
          message = errorData['detail'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }
}
