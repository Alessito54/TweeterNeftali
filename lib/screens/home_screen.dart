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
      _showSnackBar('Tweet publicado correctamente');
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
      _showSnackBar('Tweet eliminado');
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
          title: const Text('Eliminar tweet'),
          content: Text('¿Deseas eliminar este post?'),
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
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_emotions_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text('AnimeNexus'),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Chip(
                label: Text(
                  '@$username',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.person, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadTweets,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Publicar nuevo post',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                'Comparte tu fanart, captura o un pensamiento corto.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Comentario',
                        hintText: '¿Qué te inspira hoy?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(
                              _selectedImageName == null ? 'Seleccionar imagen' : 'Imagen lista',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _isCreating ? null : _createTweet,
                          icon: _isCreating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          label: const Text('Publicar'),
                        ),
                      ],
                    ),
                    if (_selectedImageBytes != null) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: Image.memory(
                            _selectedImageBytes!,
                            height: isWideScreen ? 180 : 120,
                            width: double.infinity,
                            fit: isWideScreen ? BoxFit.contain : BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading && _tweets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTweets,
                    child: _tweets.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            children: [
                              const SizedBox(height: 80),
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 76,
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Todavía no hay posts publicados',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sé el primero en compartir tu obra favorita.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _tweets.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final tweet = _tweets[index];
                              final reactions = _tweetReactions[tweet.id] ?? [];
                              final replies = _tweetReplies[tweet.id] ?? [];

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55),
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: Text(
                                                    tweet.username != null && tweet.username!.isNotEmpty
                                                        ? '@${tweet.username}'
                                                        : 'Usuario',
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  tweet.text,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w800,
                                                        height: 1.25,
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.schedule,
                                                      size: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      tweet.createdAt != null ? 'Publicado ${tweet.createdAt}' : 'Publicado hace poco',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: Colors.grey.shade600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (currentRole == 'ADMIN' || tweet.userId == currentUserId)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: IconButton(
                                                onPressed: () => _confirmDelete(tweet),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (tweet.imageUrl != null && tweet.imageUrl!.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: Container(
                                            color: Colors.grey.shade100,
                                            alignment: Alignment.center,
                                            child: Image.network(
                                              tweet.imageUrl!,
                                              height: isWideScreen ? 280 : 160,
                                              width: double.infinity,
                                              fit: isWideScreen ? BoxFit.contain : BoxFit.cover,
                                              filterQuality: FilterQuality.medium,
                                              errorBuilder: (_, __, ___) => Container(
                                                height: isWideScreen ? 280 : 160,
                                                width: double.infinity,
                                                color: Colors.grey.shade200,
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.broken_image_outlined),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      // Reactions Widget
                                      ReactionsWidget(
                                        tweetId: tweet.id!,
                                        reactions: reactions,
                                        currentUserId: currentUserId!,
                                        onReactionAdded: () => _loadReactionsAndReplies(tweet.id!),
                                        onReactionRemoved: () => _loadReactionsAndReplies(tweet.id!),
                                      ),
                                      // Replies Widget
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
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade200),
    );
  }
}
 