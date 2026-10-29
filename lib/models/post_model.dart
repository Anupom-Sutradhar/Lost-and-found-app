import 'dart:convert';
import '../config/constants.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final PostType type;
  final PostStatus status;
  final String title;
  final String description;
  final String? imageUrl;
  final String location;
  final String contactInfo;
  final String category;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.location,
    required this.contactInfo,
    required this.category,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'].toString(),
      userId: (map['user_id'] ?? '') as String,
      userName: (map['user_name'] ?? 'Unknown') as String,
      userPhotoUrl: map['user_photo_url'] as String?,
      type: PostTypeX.fromString((map['type'] ?? 'lost') as String),
      status: PostStatusX.fromString((map['status'] ?? 'active') as String),
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      imageUrl: map['image_url'] as String?,
      location: (map['location'] ?? '') as String,
      contactInfo: (map['contact_info'] ?? '') as String,
      category: (map['category'] ?? 'Other') as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String).toLocal()
          : null,
    );
  }

  /// Map for inserting a new row. `id` and `created_at` are set by Postgres.
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'type': type.value,
      'status': status.value,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'location': location,
      'contact_info': contactInfo,
      'category': category,
    };
  }

  Post copyWith({
    PostStatus? status,
    String? title,
    String? description,
    String? imageUrl,
    String? location,
    String? contactInfo,
    String? category,
    DateTime? resolvedAt,
  }) {
    return Post(
      id: id,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      type: type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      contactInfo: contactInfo ?? this.contactInfo,
      category: category ?? this.category,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  List<String> get imageUrls {
    if (imageUrl == null || imageUrl!.isEmpty) return [];
    final trimmed = imageUrl!.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [trimmed];
  }
}

class PostCategories {
  static const List<String> all = [
    'Electronics',
    'ID Card',
    'Wallet',
    'Keys',
    'Documents',
    'Bag',
    'Books',
    'Clothing',
    'Accessories',
    'Other',
  ];
}
