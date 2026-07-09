import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('php_session_cookie');
    final uri = Uri.parse('${ApiConfig.baseUrl}/$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (cookie != null) 'Cookie': cookie,
    };

    late final http.Response response;
    switch (method) {
      case 'POST':
        response =
            await _client.post(uri, headers: headers, body: jsonEncode(body));
      case 'PUT':
        response =
            await _client.put(uri, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
      default:
        response = await _client.get(uri, headers: headers);
    }

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      await prefs.setString('php_session_cookie', setCookie.split(';').first);
    }

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['error'] : null;
      throw ApiException(message?.toString() ?? 'Request failed');
    }
    return decoded;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
