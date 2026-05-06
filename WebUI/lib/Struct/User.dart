class User {
  final String username;
  String password;
  final String email;
  final bool isAdmin;
  final bool isBanned;
  final int createTime;
  final int id;

  User(
      {required this.username, this.password = '', required this.email, required this.isAdmin, required this.isBanned, required this.createTime, required this.id});

  static User? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final username = json['username'] as String?;
    final email = json['email'] as String?;
    final isAdmin = json['isAdmin'] as bool?;
    final isBanned = json['isBanned'] as bool?;

    final createTimeStr = json['createTime']?.toString();
    final idStr = json['id']?.toString();

    if (username == null || email == null || isAdmin == null ||
        isBanned == null || createTimeStr == null || idStr == null) {
      return null;
    }

    final createTime = int.tryParse(createTimeStr);
    final id = int.tryParse(idStr);

    if (createTime == null || id == null) {
      return null;
    }

    return User(username: username,
        email: email,
        isAdmin: isAdmin,
        isBanned: isBanned,
        createTime: createTime,
        id: id);
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'isAdmin': isAdmin,
      'createTime': createTime,
      'id': id
    };
  }
}

class UserPageResult {
  final List<User> data;
  final int total;
  final int page;
  final int pageSize;

  UserPageResult(
      {required this.data, required this.total, required this.page, required this.pageSize});

  static UserPageResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final rawData = json['data'];
    List<User> users = [];

    if (rawData is List) {
      for (var item in rawData) {
        if (item is Map<String, dynamic>) {
          final user = User.fromJson(item);
          if (user != null) {
            users.add(user);
          }
        }
      }
    }

    final total = int.tryParse(json['total']?.toString() ?? '');
    final page = int.tryParse(json['page']?.toString() ?? '');
    final pageSize = int.tryParse(json['pageSize']?.toString() ?? '');

    if (total == null || page == null || pageSize == null) {
      return null;
    }

    return UserPageResult(
        data: users, total: total, page: page, pageSize: pageSize);
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((u) => u.toJson()).toList(),
      'total': total,
      'page': page,
      'pageSize': pageSize
    };
  }
}
