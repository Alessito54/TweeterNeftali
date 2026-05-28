class Reply {
  final int? id;
  final String text;
  final int tweetId;
  final int userId;
  final String? username;
  final String? createdAt;

  Reply({
    this.id,
    required this.text,
    required this.tweetId,
    required this.userId,
    this.username,
    this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
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

    return Reply(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      text: json['text']?.toString() ?? '',
      tweetId: json['tweetId'] is int ? json['tweetId'] : int.tryParse(json['tweetId']?.toString() ?? '0') ?? 0,
      userId: parsedUserId,
      username: json['User'] is Map ? (json['User'] as Map)['username'] : json['username'],
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'tweetId': tweetId,
      'userId': userId,
    };
  }
}
