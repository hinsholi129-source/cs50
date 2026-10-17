import 'dart:convert';
import 'comment.dart';

class Discussion {
  final String id;
  final String title;
  final String content;
  final String category;
  final String? imageUrl; // URL gambar untuk topik (opsional)
  final DateTime timestamp;
  final List<Comment> comments;
  final String userId; // ID pengguna yang membuat topik
  int likeCount; // jumlah menyukai topik

  Discussion({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl,
    required this.userId,
    DateTime? timestamp,
    List<Comment>? comments,
    this.likeCount = 0,
  })  : timestamp = timestamp ?? DateTime.now(),
        comments = comments ?? [];

  int get commentCount => comments.length;

  // Konversi ke JSON untuk penyimpanan
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'imageUrl': imageUrl,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'likeCount': likeCount,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  // Membuat objek Discussion dari JSON
  factory Discussion.fromJson(Map<String, dynamic> json) => Discussion(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        category: json['category'],
        imageUrl: json['imageUrl'],
        userId: json['userId'],
        timestamp: DateTime.parse(json['timestamp']),
        likeCount: json['likeCount'],
        comments: (json['comments'] as List<dynamic>?)
                ?.map((c) => Comment.fromJson(c))
                .toList() ?? [],
      );

  // Membuat salinan Discussion dengan beberapa field yang berubah
  Discussion copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? imageUrl,
    DateTime? timestamp,
    List<Comment>? comments,
    String? userId,
    int? likeCount,
  }) {
    return Discussion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      comments: comments ?? this.comments,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}