import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RedditAccount {
  final String id;
  String displayName;
  String? username;
  String? avatarUrl;
  final DateTime createdAt;
  DateTime lastUsedAt;
  final List<Cookie> cookies;

  RedditAccount({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
    required this.createdAt,
    required this.lastUsedAt,
    required this.cookies,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'username': username,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'cookies': cookies.map((c) => c.toMap()).toList(),
      };

  factory RedditAccount.fromJson(Map<String, dynamic> json) => RedditAccount(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        username: json['username'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
        cookies: (json['cookies'] as List)
            .map((c) =>
                Cookie.fromMap(c as Map<String, dynamic>))
            .whereType<Cookie>()
            .toList(),
      );
}
