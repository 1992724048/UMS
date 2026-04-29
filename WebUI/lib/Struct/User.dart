class User {
  final String username;
  String password;
  String email;
  bool isAdmin;
  final int createTime;
  final int id;

  User({
    required this.username,
    this.password = '',
    required this.email,
    required this.isAdmin,
    required this.createTime,
    required this.id,
  });

  static User? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    print(json);

    final username = json['Username'] as String?;
    final email = json['Email'] as String?;
    final isAdmin = json['IsAdmin'] as bool?;
    final createTime = json['CreateTime'] as int?;
    final id = json['Id'] as int?;

    print(username);

    if (username == null ||
        email == null ||
        isAdmin == null ||
        createTime == null ||
        id == null) {
      return null;
    }

    return User(
      username: username,
      email: email,
      isAdmin: isAdmin,
      createTime: createTime,
      id: id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'isAdmin': isAdmin,
      'createTime': createTime,
      'id': id,
    };
  }
}
