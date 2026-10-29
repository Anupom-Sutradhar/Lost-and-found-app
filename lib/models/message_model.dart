class Conversation {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  // Joined fields (populated after query)
  final String? otherUserName;
  final String? otherUserPhotoUrl;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.unreadCount = 0,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    return Conversation(
      id: map['id'] as String,
      user1Id: map['user1_id'] as String,
      user2Id: map['user2_id'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String).toLocal()
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  String otherUserId(String myId) => user1Id == myId ? user2Id : user1Id;

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    String? otherUserName,
    String? otherUserPhotoUrl,
    int? unreadCount,
  }) {
    return Conversation(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      isRead: (map['is_read'] ?? false) as bool,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    };
  }
}
