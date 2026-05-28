class User {
  final int? id;
  final String username;
  final String? email;
  final String? role;

  User({
    this.id,
    required this.username,
    this.email,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final username = json['username'];
    final email = json['email'];
    final role = json['role'];
    
    return User(
      id: id is int ? id : (id is String ? int.tryParse(id) : null),
      username: username is String ? username : username?.toString() ?? '',
      email: email is String ? email : email?.toString(),
      role: role is String ? role : role?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
    };
  }
}
