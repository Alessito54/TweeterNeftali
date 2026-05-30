import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/tweet.dart';
import '../models/reaction.dart';
import '../models/reply.dart';
import '../services/auth_service.dart';
import '../services/tweet_service.dart';
import '../widgets/reactions_widget.dart';
import '../widgets/replies_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();

  final TextEditingController _textController = TextEditingController();

  List<Tweet> _tweets = [];
  Map<int, List<Reaction>> _tweetReactions = {};
  Map<int, List<Reply>> _tweetReplies = {};
  bool _isLoading = false;
  bool _isCreating = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTweets();
  }

  Future<void> _loadTweets() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final tweets = await _tweetService.fetchTweets();
      if (mounted) {
        setState(() {
          _tweets = tweets;
        });

        _tweetReactions.clear();
        _tweetReplies.clear();

        for (var tweet in tweets) {
          if (tweet.id != null) {
            if (tweet.reactions != null && tweet.reactions!.isNotEmpty) {
              _tweetReactions[tweet.id!] = tweet.reactions!
                  .map((r) => r is Reaction ? r : Reaction.fromJson(r as Map<String, dynamic>))
                  .toList();
            } else {
              _tweetReactions[tweet.id!] = [];
            }

            if (tweet.replies != null && tweet.replies!.isNotEmpty) {
              _tweetReplies[tweet.id!] = tweet.replies!
                  .map((r) => r is Reply ? r : Reply.fromJson(r as Map<String, dynamic>))
                  .toList();
            } else {
              _tweetReplies[tweet.id!] = [];
            }
          }
        }

        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudieron cargar los tweets: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReactionsAndReplies(int tweetId) async {
    try {
      final reactions = await _tweetService.getReactions(tweetId);
      final replies = await _tweetService.getReplies(tweetId);

      if (mounted) {
        setState(() {
          _tweetReactions[tweetId] = reactions;
          _tweetReplies[tweetId] = replies;
        });
      }
    } catch (e) {
      print('Error loading reactions/replies for tweet $tweetId: $e');
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;
    if (file.bytes == null) {
      _showSnackBar('No se pudo leer la imagen seleccionada', isError: true);
      return;
    }

    setState(() {
      _selectedImageBytes = file.bytes;
      _selectedImageName = file.name;
    });
  }

  Future<void> _createTweet() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      _showSnackBar('Escribe un comentario para publicar', isError: true);
      return;
    }

    if (_selectedImageBytes != null && _selectedImageName == null) {
      _showSnackBar('Selecciona una imagen válida', isError: true);
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await _tweetService.createTweet(
        text: text,
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
      );

      _textController.clear();

      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });

      await _loadTweets();
      _showSnackBar('Post publicado correctamente');
    } catch (e) {
      _showSnackBar('Error al publicar: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _deleteTweet(int? id) async {
    if (id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _tweetService.deleteTweet(id);
      await _loadTweets();
      _showSnackBar('Post eliminado');
    } catch (e) {
      _showSnackBar('Error al eliminar: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _confirmDelete(Tweet tweet) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar post'),
          content: const Text('¿Deseas eliminar este post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTweet(tweet.id);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 900;
    final username = _authService.getUsername() ?? 'admin';
    final currentUserId = _authService.getUserId();
    final currentRole = (_authService.getRole() ?? 'USER').toUpperCase();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom AppBar estilo anime
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF0F1419)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AnimeNexus',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Comunidad de fans',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: Text(
                          username.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Tooltip(
                message: 'Refrescar',
                child: IconButton(
                  onPressed: _isLoading ? null : _loadTweets,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ),
              Tooltip(
                message: 'Cerrar sesión',
                child: IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          // Contenido principal
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Tarjeta de composición flotante
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E1B4B), Color(0xFF440066)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¿Qué te inspira hoy?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Comparte tu pasión',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _textController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          hintText: 'Escribe algo increíble...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_rounded),
                            label: Text(
                              _selectedImageName == null ? 'Imagen' : '✓ Listo',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isCreating ? null : _createTweet,
                              icon: _isCreating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: const Text('Publicar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedImageBytes != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _selectedImageBytes!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Error banner
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_rounded, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Feed de posts
          if (_isLoading && _tweets.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tweets.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.forum_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Sin posts todavía',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sé el primero en compartir',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tweet = _tweets[index];
                  final reactions = _tweetReactions[tweet.id] ?? [];
                  final replies = _tweetReplies[tweet.id] ?? [];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '@${tweet.username}',
                                        style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      tweet.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (currentRole == 'ADMIN' || tweet.userId == currentUserId)
                                IconButton(
                                  onPressed: () => _confirmDelete(tweet),
                                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                                  iconSize: 20,
                                ),
                            ],
                          ),
                          if (tweet.imageUrl != null && tweet.imageUrl!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                tweet.imageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ReactionsWidget(
                            tweetId: tweet.id!,
                            reactions: reactions,
                            currentUserId: currentUserId!,
                            onReactionAdded: () => _loadReactionsAndReplies(tweet.id!),
                            onReactionRemoved: () => _loadReactionsAndReplies(tweet.id!),
                          ),
                          RepliesWidget(
                            tweetId: tweet.id!,
                            replies: replies,
                            currentUserId: currentUserId!,
                            onReplyAdded: () => _loadReactionsAndReplies(tweet.id!),
                            onReplyRemoved: () => _loadReactionsAndReplies(tweet.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _tweets.length,
              ),
            ),
        ],
      ),
    );
  }
}
