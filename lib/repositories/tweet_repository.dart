import '../models/tweet.dart';
import '../models/reaction.dart';
import '../models/reply.dart';
import 'dart:typed_data';

/// Abstract interface for Twitter repository operations
/// Follows the Dependency Inversion Principle (DIP)
/// Allows for different implementations (HTTP, local cache, mock, etc.)
abstract class ITweetRepository {
  /// Fetch all tweets
  Future<List<Tweet>> fetchTweets();

  /// Create a new tweet
  Future<Tweet> createTweet({
    required String text,
    String? motoMarca,
    String? motoModelo,
    int? motoCilindrada,
    Uint8List? imageBytes,
    String? imageName,
  });

  /// Delete a tweet by ID
  Future<void> deleteTweet(int id);

  /// Add a reaction to a tweet
  Future<Reaction> addReaction(int tweetId, String emoji);

  /// Remove a reaction from a tweet
  Future<void> removeReaction(int reactionId);

  /// Get reactions for a tweet
  Future<List<Reaction>> getReactions(int tweetId);

  /// Add a reply to a tweet
  Future<Reply> addReply(int tweetId, String text);

  /// Remove a reply
  Future<void> removeReply(int replyId);

  /// Get replies for a tweet
  Future<List<Reply>> getReplies(int tweetId);

  /// Cleanup resources
  void dispose();
}
