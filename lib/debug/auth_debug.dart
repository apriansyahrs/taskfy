import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taskfy/utils/logger_util.dart';

class AuthDebugger {
  /// Test the API endpoint directly
  static Future<void> testLoginEndpoint(String url, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      
      LoggerUtil.log('API Response Status: ${response.statusCode}', tag: 'DEBUG');
      LoggerUtil.log('API Response Body: ${response.body}', tag: 'DEBUG');
      
      return;
    } catch (e) {
      LoggerUtil.error('Error testing endpoint', tag: 'DEBUG', error: e);
      rethrow;
    }
  }
  
  static void validateEmailFormat(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      LoggerUtil.error('Invalid email format: $email', tag: 'DEBUG');
    } else {
      LoggerUtil.log('Email format valid: $email', tag: 'DEBUG');
    }
  }
}
