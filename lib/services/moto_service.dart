import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/moto.dart';
import 'auth_service.dart';

class MotoService {
  static final MotoService _instance = MotoService._internal();

  late http.Client _httpClient;
  late String _baseUrl;

  factory MotoService() {
    return _instance;
  }

  MotoService._internal() {
    _httpClient = http.Client();
    _baseUrl = _resolveBaseUrl();
  }

  String _resolveBaseUrl() {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Default to Node.js/Express server running on port 3000 with '/api' prefix.
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

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = AuthService.getInstance().getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<List<Moto>> fetchMotos() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/motos'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> motosData = decoded is List
          ? decoded
          : (decoded['motos'] as List<dynamic>? ?? []);
      return motosData
          .map((json) => Moto.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    }

    throw Exception('Error al obtener motos: ${response.statusCode}');
  }

  Future<Moto> createMoto({
    required String marca,
    required String modelo,
    required int cilindrada,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    final uri = Uri.parse('$_baseUrl/motos');
    final request = http.MultipartRequest('POST', uri)
      ..fields['marca'] = marca
      ..fields['modelo'] = modelo
      ..fields['cilindrada'] = cilindrada.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          imageBytes,
          filename: imageName,
        ),
      );

    // Add headers (including Authorization if available)
    final token = AuthService.getInstance().getToken();
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Moto.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw Exception('Error al crear moto: ${response.statusCode}');
  }

  Future<void> deleteMoto(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl/motos/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar moto: ${response.statusCode}');
    }
  }

  void dispose() {
    // Intentionally left open: this singleton is reused across screens.
  }
}
