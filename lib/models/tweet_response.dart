import 'tweet.dart';

/// Model for the tweets API endpoint.
class TweetResponse {
  final List<Tweet> content;

  TweetResponse({
    required this.content,
  });

  factory TweetResponse.fromJson(Map<String, dynamic> json) {
    final contentList = (json['tweets'] ?? json['content']) as List<dynamic>? ?? [];
    return TweetResponse(
      content: contentList
          .map((tweet) {
            final tweetMap = Map<String, dynamic>.from(tweet as Map);
            return Tweet.fromJson(tweetMap);
          })
          .toList(),
    );
  }

  @override
  String toString() =>
      'TweetResponse(content: ${content.length})';
}
