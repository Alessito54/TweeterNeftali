class Reaction {
  final int? id;
  final String emoji;
  final int tweetId;
  final int userId;
  final String? username;
  final String? createdAt;

  Reaction({
    this.id,
    required this.emoji,
    required this.tweetId,
    required this.userId,
    this.username,
    this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    // Parse userId - puede venir de userId, User.id, o como string/int
    int parsedUserId = 0;
    if (json['userId'] != null) {
      parsedUserId = json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? '0') ?? 0;
    } else if (json['User'] != null && json['User'] is Map) {
      final userMap = json['User'] as Map<String, dynamic>;
      if (userMap['id'] != null) {
        parsedUserId = userMap['id'] is int ? userMap['id'] : int.tryParse(userMap['id']?.toString() ?? '0') ?? 0;
      }
    }

    return Reaction(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      emoji: json['emoji']?.toString() ?? '👍',
      tweetId: json['tweetId'] is int ? json['tweetId'] : int.tryParse(json['tweetId']?.toString() ?? '0') ?? 0,
      userId: parsedUserId,
      username: json['User'] is Map ? (json['User'] as Map)['username'] : json['username'],
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'tweetId': tweetId,
      'userId': userId,
    };
  }
}
