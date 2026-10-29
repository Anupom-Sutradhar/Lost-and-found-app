import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _myId => _client.auth.currentUser?.id;

  /// Get or create a conversation between current user and [otherUserId].
  /// Uses the Postgres function for atomic get-or-create.
  Future<String> getOrCreateConversation(String otherUserId) async {
    final myId = _myId;
    if (myId == null) throw 'Not signed in';

    final result = await _client.rpc('get_or_create_conversation', params: {
      'p_user1': myId,
      'p_user2': otherUserId,
    });

    return result as String;
  }

  /// Fetch all conversations for the current user, with the other user's
  /// profile info and unread count.
  Future<List<Conversation>> fetchConversations() async {
    final myId = _myId;
    if (myId == null) return [];

    final rows = await _client
        .from(AppConstants.conversationsTable)
        .select()
        .or('user1_id.eq.$myId,user2_id.eq.$myId')
        .order('last_message_at', ascending: false);

    final conversations = <Conversation>[];
    for (final row in rows) {
      var conv = Conversation.fromMap(row as Map<String, dynamic>, currentUserId: myId);
      final otherId = conv.otherUserId(myId);

      // Fetch other user's profile
      final profile = await _client
          .from(AppConstants.usersTable)
          .select('name, photo_url')
          .eq('id', otherId)
          .maybeSingle();

      // Count unread messages
      final unreadResult = await _client
          .from(AppConstants.messagesTable)
          .select()
          .eq('conversation_id', conv.id)
          .neq('sender_id', myId)
          .eq('is_read', false);

      conv = conv.copyWith(
        otherUserName: profile?['name'] as String? ?? 'Student',
        otherUserPhotoUrl: profile?['photo_url'] as String?,
        unreadCount: (unreadResult as List).length,
      );

      conversations.add(conv);
    }

    return conversations;
  }

  /// Stream messages for a conversation (real-time).
  Stream<List<Message>> streamMessages(String conversationId) {
    return _client
        .from(AppConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(Message.fromMap).toList());
  }

  /// Send a message in a conversation.
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final myId = _myId;
    if (myId == null) throw 'Not signed in';

    final msg = Message(
      id: '',
      conversationId: conversationId,
      senderId: myId,
      content: content,
      createdAt: DateTime.now(),
    );

    await _client.from(AppConstants.messagesTable).insert(msg.toInsertMap());

    // Update conversation's last message
    await _client.from(AppConstants.conversationsTable).update({
      'last_message': content,
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);
  }

  /// Mark all messages from the other user as read.
  Future<void> markAsRead(String conversationId) async {
    final myId = _myId;
    if (myId == null) return;

    await _client
        .from(AppConstants.messagesTable)
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', myId)
        .eq('is_read', false);
  }

  /// Get the total unread message count for badge display.
  Future<int> getUnreadCount() async {
    final myId = _myId;
    if (myId == null) return 0;

    try {
      // Get all conversation IDs for this user
      final convos = await _client
          .from(AppConstants.conversationsTable)
          .select('id')
          .or('user1_id.eq.$myId,user2_id.eq.$myId');

      if ((convos as List).isEmpty) return 0;

      final convoIds = convos.map((c) => c['id'] as String).toList();

      int total = 0;
      for (final cid in convoIds) {
        final msgs = await _client
            .from(AppConstants.messagesTable)
            .select()
            .eq('conversation_id', cid)
            .neq('sender_id', myId)
            .eq('is_read', false);
        total += (msgs as List).length;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Fetch the other user's profile for a conversation.
  Future<AppUser?> fetchOtherUser(String otherUserId) async {
    final data = await _client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', otherUserId)
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }
}
