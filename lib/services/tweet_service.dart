import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/tweet.dart';
import '../models/tweet_response.dart';
import '../models/reaction.dart';
import '../models/reply.dart';
import '../repositories/tweet_repository.dart';
import 'auth_service.dart';

class TweetService implements ITweetRepository {
  static final TweetService _instance = TweetService._internal();

  late final http.Client _httpClient;
  late final AuthService _authService;
  late final String _baseUrl;

  TweetService._internal() {
    _httpClient = http.Client();
    _authService = AuthService();
    _baseUrl = _resolveBaseUrl();
  }

  factory TweetService() => _instance;

  static TweetService getInstance() => _instance;

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

  Future<void> _ensureAuth() async {
    await _authService.init();
  }

  Map<String, String> _getJsonHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = _authService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      print('[DEBUG] No token found in auth service');
    }

    return headers;
  }

  Map<String, String> _getMultipartHeaders() {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = _authService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('[DEBUG] Token added to multipart headers');
    } else {
      print('[DEBUG] No token found for multipart request');
    }
    return headers;
  }

  @override
  Future<List<Tweet>> fetchTweets() async {
    await _ensureAuth();

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/tweets'),
      headers: _getJsonHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final tweetResponse = TweetResponse.fromJson(Map<String, dynamic>.from(decoded as Map));
      return tweetResponse.content;
    }

    throw Exception('Failed to load tweets. Status code: ${response.statusCode}');
  }

  @override
  Future<Tweet> createTweet({
    required String text,
    String? motoMarca,
    String? motoModelo,
    int? motoCilindrada,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    await _ensureAuth();

    final token = _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please log in again.');
    }

    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/tweets'))
      ..fields['text'] = text;

    if (motoMarca != null && motoMarca.isNotEmpty) {
      request.fields['motoMarca'] = motoMarca;
    }
    if (motoModelo != null && motoModelo.isNotEmpty) {
      request.fields['motoModelo'] = motoModelo;
    }
    if (motoCilindrada != null) {
      request.fields['motoCilindrada'] = motoCilindrada.toString();
    }
    if (imageBytes != null && imageName != null && imageName.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          imageBytes,
          filename: imageName,
        ),
      );
    }

    request.headers.addAll(_getMultipartHeaders());

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    print('[DEBUG] Tweet creation response: ${response.statusCode}');
    print('[DEBUG] Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Tweet.fromJson(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    }

    throw Exception('Failed to create tweet. Status: ${response.statusCode}. Message: ${response.body}');
  }

  @override
  Future<void> deleteTweet(int id) async {
    await _ensureAuth();

    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl/tweets/$id'),
      headers: _getJsonHeaders(),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete tweet. Status code: ${response.statusCode}');
    }
  }

  @override
  Future<Reaction> addReaction(int tweetId, String emoji) async {
    await _ensureAuth();

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/tweets/$tweetId/reactions'),
      headers: _getJsonHeaders(),
      body: jsonEncode({'emoji': emoji}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final reactionsJson = decoded['reactions'] as List<dynamic>? ?? [];
      // Retornar la primera reacción, pero idealmente el frontend recargaría todas
      if (reactionsJson.isNotEmpty) {
        return Reaction.fromJson(Map<String, dynamic>.from(reactionsJson.first as Map));
      }
      // Si no hay reacciones, retornar una reacción vacía (se recargará en el UI)
      return Reaction(emoji: '', tweetId: tweetId, userId: -1);
    }

    throw Exception('Failed to add reaction. Status: ${response.statusCode}. Message: ${response.body}');
  }

  @override
  Future<void> removeReaction(int reactionId) async {
    await _ensureAuth();

    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl/reactions/$reactionId'),
      headers: _getJsonHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove reaction. Status: ${response.statusCode}');
    }
  }

  @override
  Future<List<Reaction>> getReactions(int tweetId) async {
    await _ensureAuth();

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/tweets/$tweetId/reactions'),
      headers: _getJsonHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final reactions = decoded['reactions'] as List<dynamic>? ?? [];
      return reactions.map((r) => Reaction.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    }

    throw Exception('Failed to load reactions. Status code: ${response.statusCode}');
  }

  @override
  Future<Reply> addReply(int tweetId, String text) async {
    await _ensureAuth();

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/tweets/$tweetId/replies'),
      headers: _getJsonHeaders(),
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reply.fromJson(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    }

    throw Exception('Failed to create reply. Status: ${response.statusCode}. Message: ${response.body}');
  }

  @override
  Future<void> removeReply(int replyId) async {
    await _ensureAuth();

    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl/replies/$replyId'),
      headers: _getJsonHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete reply. Status: ${response.statusCode}');
    }
  }

  @override
  Future<List<Reply>> getReplies(int tweetId) async {
    await _ensureAuth();

    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/tweets/$tweetId/replies'),
      headers: _getJsonHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final replies = decoded['replies'] as List<dynamic>? ?? [];
      return replies.map((r) => Reply.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    }

    throw Exception('Failed to load replies. Status code: ${response.statusCode}');
  }

  @override
  void dispose() {
    // Intentionally left open: this singleton is reused across screens.
  }
}
