import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  SharedPreferences? _prefs;
  late final http.Client _httpClient;
  late final String _baseUrl;

  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _userIdKey = 'auth_user_id';
  static const String _roleKey = 'auth_role';

  AuthService._internal() {
    _httpClient = http.Client();
    _baseUrl = _resolveBaseUrl();
  }

  factory AuthService() => _instance;

  static AuthService getInstance() => _instance;

  String _resolveBaseUrl() {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      // En web, usar 127.0.0.1 en lugar de localhost para mayor compatibilidad
      return 'http://127.0.0.1:3000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      default:
        return 'http://127.0.0.1:3000/api';
    }
  }

  Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    await _ensureInit();
  }

  Map<String, dynamic> _parseResponse(String body) {
    final decoded = jsonDecode(body);
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<User> register({
    required String username,
    required String password,
  }) async {
    await _ensureInit();

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final error = _safeError(response.body);
      throw Exception(error);
    }

    final parsed = _parseResponse(response.body);
    await _saveSession(parsed);
    return User.fromJson(Map<String, dynamic>.from(parsed['user'] as Map));
  }

  Future<User> login(String username, String password) async {
    await _ensureInit();

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final error = _safeError(response.body);
      throw Exception(error);
    }

    final parsed = _parseResponse(response.body);
    await _saveSession(parsed);
    return User.fromJson(Map<String, dynamic>.from(parsed['user'] as Map));
  }

  Future<void> _saveSession(Map<String, dynamic> parsed) async {
    final token = parsed['token']?.toString() ?? '';
    final user = Map<String, dynamic>.from(parsed['user'] as Map);

    await _prefs!.setString(_tokenKey, token);
    await _prefs!.setString(_usernameKey, user['username']?.toString() ?? '');
    await _prefs!.setString(_userIdKey, user['id']?.toString() ?? '');
    await _prefs!.setString(_roleKey, user['role']?.toString() ?? 'USER');
  }

  String _safeError(String body) {
    try {
      final parsed = _parseResponse(body);
      return parsed['error']?.toString() ?? 'Error de autenticación';
    } catch (_) {
      return 'Error de autenticación';
    }
  }

  bool isAuthenticated() {
    if (_prefs == null) return false;
    return (_prefs!.getString(_tokenKey) ?? '').isNotEmpty;
  }

  String? getToken() {
    if (_prefs == null) return null;
    final token = _prefs!.getString(_tokenKey);
    return token != null && token.isNotEmpty ? token : null;
  }

  String? getUsername() => _prefs?.getString(_usernameKey);

  int? getUserId() {
    final raw = _prefs?.getString(_userIdKey);
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  String? getRole() => _prefs?.getString(_roleKey);

  Future<void> logout() async {
    await _ensureInit();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_usernameKey);
    await _prefs!.remove(_userIdKey);
    await _prefs!.remove(_roleKey);
  }

  void dispose() {
    // Intentionally left open: this singleton is reused across screens.
  }
}
