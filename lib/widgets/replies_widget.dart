import 'package:flutter/material.dart';
import '../models/reply.dart';
import '../services/tweet_service.dart';
import '../services/auth_service.dart';

class RepliesWidget extends StatefulWidget {
  final int tweetId;
  final List<Reply> replies;
  final int currentUserId;
  final VoidCallback onReplyAdded;
  final VoidCallback onReplyRemoved;

  const RepliesWidget({
    super.key,
    required this.tweetId,
    required this.replies,
    required this.currentUserId,
    required this.onReplyAdded,
    required this.onReplyRemoved,
  });

  @override
  State<RepliesWidget> createState() => _RepliesWidgetState();
}

class _RepliesWidgetState extends State<RepliesWidget> {
  final TweetService _tweetService = TweetService();
  final AuthService _authService = AuthService();
  final TextEditingController _replyController = TextEditingController();
  bool _isLoading = false;
  bool _showReplies = false;

  Future<void> _addReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _tweetService.addReply(widget.tweetId, text);
      _replyController.clear();
      widget.onReplyAdded();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respuesta publicada')),
        );
      }
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

  Future<void> _deleteReply(Reply reply) async {
    final isAdmin = _authService.getRole() == 'ADMIN';
    final isOwner = reply.userId == widget.currentUserId;

    if (!isAdmin && !isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes permiso para eliminar esta respuesta')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _tweetService.removeReply(reply.id!);
      widget.onReplyRemoved();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respuesta eliminada')),
        );
      }
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
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _authService.getRole() == 'ADMIN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Replies count button
        TextButton.icon(
          onPressed: () {
            setState(() => _showReplies = !_showReplies);
          },
          icon: Icon(_showReplies ? Icons.expand_less : Icons.expand_more),
          label: Text('${widget.replies.length} respuesta${widget.replies.length != 1 ? 's' : ''}'),
        ),
        // Reply input
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'Responder...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  enabled: !_isLoading,
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _addReply,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar'),
              ),
            ],
          ),
        ),
        // Show/hide replies list
        if (_showReplies && widget.replies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.replies.map((reply) {
                final isOwner = reply.userId == widget.currentUserId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '@${reply.username}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOwner || isAdmin)
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _deleteReply(reply),
                                  icon: const Icon(Icons.close, size: 16),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reply.text,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reply.createdAt ?? 'Hace poco',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
