import 'dart:convert';

class Comment {
  final String id;
  final String content;
  final DateTime timestamp;
  final String userId; // ID pengguna yang membuat komentar
  int likeCount; // jumlah menyukai komentar

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    DateTime? timestamp,
    this.likeCount = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  // Konversi ke JSON untuk penyimpanan
  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'likeCount': likeCount,
      };

  // Membuat objek Comment dari JSON
  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'],
        content: json['content'],
        userId: json['userId'],
        timestamp: DateTime.parse(json['timestamp']),
        likeCount: json['likeCount'],
      );

  // Membuat salinan Comment dengan beberapa field yang berubah
  Comment copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    String? userId,
    int? likeCount,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}