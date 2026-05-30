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
    final username = _authService.getUsername() ?? 'animefan';
    final currentUserId = _authService.getUserId();
    final currentRole = (_authService.getRole() ?? 'USER').toUpperCase();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1020), Color(0xFF151A33), Color(0xFF1F1234)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFF12172A),
              expandedHeight: 172,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(18, 76, 18, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6D28D9), Color(0xFFDB2777), Color(0xFF0B1020)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        child: const Text(
                          'AnimeNexus // feed',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tu rincón anime',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Comparte teorías, fanart, reseñas y reacciones.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _isLoading ? null : _loadTweets,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: 'Refrescar',
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF14192E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@$username',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Escribe algo de anime hoy',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _textController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ej: Terminando temporada de Jujutsu, qué joya...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(_selectedImageName == null ? 'Portada / fanart' : 'Imagen lista'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _isCreating ? null : _createTweet,
                            icon: _isCreating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: const Text('Publicar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEC4899),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedImageBytes != null) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            _selectedImageBytes!,
                            height: isWideScreen ? 180 : 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (_isLoading && _tweets.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tweets.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6D28D9), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(Icons.palette_rounded, color: Colors.white, size: 42),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no hay publicaciones',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comparte tu primera publicación anime y empieza el feed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tweet = _tweets[index];
                      final reactions = _tweetReactions[tweet.id] ?? [];
                      final replies = _tweetReplies[tweet.id] ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171C34),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        tweet.username != null && tweet.username!.isNotEmpty
                                            ? tweet.username![0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tweet.username != null && tweet.username!.isNotEmpty
                                              ? '@${tweet.username}'
                                              : 'animefan',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          tweet.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            height: 1.45,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule_rounded, size: 14, color: Colors.white70),
                                            const SizedBox(width: 6),
                                            Text(
                                              tweet.createdAt != null ? 'Publicado ${tweet.createdAt}' : 'Publicado hace poco',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (currentRole == 'ADMIN' || tweet.userId == currentUserId)
                                    IconButton(
                                      onPressed: () => _confirmDelete(tweet),
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    ),
                                ],
                              ),
                              if (tweet.imageUrl != null && tweet.imageUrl!.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    tweet.imageUrl!,
                                    height: isWideScreen ? 280 : 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: isWideScreen ? 280 : 180,
                                      alignment: Alignment.center,
                                      color: Colors.white10,
                                      child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
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
              ),
          ],
        ),
      ),
    );
  }
}
