import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class DbService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Posts ────────────────────────────────────────────────────────────────


  Stream<List<Post>> streamPosts({
    PostType? type,
    PostStatus? status,
    String? category,
  }) {
    final stream = _client
        .from(AppConstants.postsTable)
        .stream(primaryKey: ['id']).order('created_at', ascending: false);

    return stream.map((rows) {
      var posts = rows.map(Post.fromMap).toList();

      if (type != null) {
        posts = posts.where((p) => p.type == type).toList();
      }
      if (status != null) {
        posts = posts.where((p) => p.status == status).toList();
      }
      if (category != null && category != 'All') {
        posts = posts.where((p) => p.category == category).toList();
      }
      return posts;
    });
  }

  /// Stream posts created by a specific user (My Posts screen).
  Stream<List<Post>> streamUserPosts(String userId) {
    return _client
        .from(AppConstants.postsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Post.fromMap).toList());
  }

  /// One-time search by title (case-insensitive `ilike` match).
  Future<List<Post>> searchPosts(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final rows = await _client
        .from(AppConstants.postsTable)
        .select()
        .ilike('title', '%$q%')
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List).map((r) => Post.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Fetch a single post.
  Future<Post?> getPost(String postId) async {
    final data = await _client
        .from(AppConstants.postsTable)
        .select()
        .eq('id', postId)
        .maybeSingle();
    if (data == null) return null;
    return Post.fromMap(data);
  }

  /// Insert a new post. Returns the inserted row's id.
  Future<String> createPost(Post post) async {
    final inserted = await _client
        .from(AppConstants.postsTable)
        .insert(post.toInsertMap())
        .select('id')
        .single();
    return inserted['id'].toString();
  }

  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    await _client
        .from(AppConstants.postsTable)
        .update(updates)
        .eq('id', postId);
  }

  Future<void> markResolved(String postId) async {
    await _client.from(AppConstants.postsTable).update({
      'status': PostStatus.resolved.value,
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', postId);
  }

  Future<void> deletePost(String postId) async {
    await _client.from(AppConstants.postsTable).delete().eq('id', postId);
  }

  // ─── Users ────────────────────────────────────────────────────────────────

  Future<AppUser?> getUser(String uid) async {
    final data = await _client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    await _client
        .from(AppConstants.usersTable)
        .update(updates)
        .eq('id', uid);
  }
}
