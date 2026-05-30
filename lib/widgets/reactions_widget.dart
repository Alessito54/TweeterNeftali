import 'package:flutter/material.dart';
import '../models/reaction.dart';
import '../services/tweet_service.dart';

class ReactionsWidget extends StatefulWidget {
  final int tweetId;
  final List<Reaction> reactions;
  final int currentUserId;
  final VoidCallback onReactionAdded;
  final VoidCallback onReactionRemoved;

  const ReactionsWidget({
    super.key,
    required this.tweetId,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionAdded,
    required this.onReactionRemoved,
  });

  @override
  State<ReactionsWidget> createState() => _ReactionsWidgetState();
}

class _ReactionsWidgetState extends State<ReactionsWidget> {
  final TweetService _tweetService = TweetService();
  late Map<String, int> _reactionCounts;
  late String? _userReaction;
  bool _isLoading = false;

  static const List<String> _availableEmojis = ['👍', '❤️', '😂', '😢', '🔥', '🎉'];

  @override
  void initState() {
    super.initState();
    _updateReactionCounts();
  }

  @override
  void didUpdateWidget(ReactionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reactions.length != widget.reactions.length ||
        (oldWidget.reactions.isNotEmpty && oldWidget.reactions.toString() != widget.reactions.toString())) {
      _updateReactionCounts();
    }
  }

  void _updateReactionCounts() {
    _reactionCounts = {};
    _userReaction = null;

    print('[DEBUG] Reactions widget - Total reactions: ${widget.reactions.length}');

    for (var reaction in widget.reactions) {
      print('[DEBUG] Reaction: emoji=${reaction.emoji}, userId=${reaction.userId}, currentUser=${widget.currentUserId}');
      
      // Contar todas las reacciones por emoji
      _reactionCounts[reaction.emoji] = (_reactionCounts[reaction.emoji] ?? 0) + 1;

      // Guardar la reacción del usuario actual
      if (reaction.userId == widget.currentUserId) {
        _userReaction = reaction.emoji;
        print('[DEBUG] User has reacted with: ${reaction.emoji}');
      }
    }

    print('[DEBUG] Final counts: $_reactionCounts');
    print('[DEBUG] User current reaction: $_userReaction');
  }

  Future<void> _toggleReaction(String emoji) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_userReaction == emoji) {
        // Si hace clic en el mismo emoji que ya tiene, eliminar
        final reaction = widget.reactions.firstWhere(
          (r) => r.userId == widget.currentUserId,
          orElse: () => Reaction(
            emoji: emoji,
            tweetId: widget.tweetId,
            userId: widget.currentUserId,
          ),
        );
        if (reaction.id != null) {
          await _tweetService.removeReaction(reaction.id!);
        }
      } else {
        // Agregar o cambiar reacción
        await _tweetService.addReaction(widget.tweetId, emoji);
      }
      
      // IMPORTANTE: Recargar todas las reacciones después del cambio
      widget.onReactionAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display existing reactions
        if (_reactionCounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _reactionCounts.entries.map((entry) {
              final emoji = entry.key;
              final count = entry.value;
              final isUserReaction = _userReaction == emoji;

              return ActionChip(
                onPressed: () => _toggleReaction(emoji),
                backgroundColor: isUserReaction
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade100,
                side: BorderSide(
                  color: isUserReaction
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
                label: Text(
                  '$emoji $count',
                  style: TextStyle(
                    fontFamilyFallback: const ['Noto Color Emoji'],
                    color: isUserReaction
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade700,
                    fontWeight: isUserReaction ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        // Add reaction button
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._availableEmojis.map((emoji) {
                final isUserReaction = _userReaction == emoji;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleReaction(emoji),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Opacity(
                          opacity: isUserReaction ? 1.0 : (_userReaction == null ? 0.6 : 0.3),
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontFamily: 'Noto Color Emoji',
                              fontFamilyFallback: const ['Noto Color Emoji'],
                              fontSize: 20,
                              fontWeight: isUserReaction ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
