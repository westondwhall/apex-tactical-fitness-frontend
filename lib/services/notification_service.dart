import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
  }

  static Future<void> requestPermissions() async {
    // No platform permissions are required for this stub.
  }
}
