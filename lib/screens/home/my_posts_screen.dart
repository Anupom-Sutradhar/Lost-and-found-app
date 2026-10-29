import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/post_card.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().supabaseUser?.id;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }
    final fs = DbService();

    return StreamBuilder<List<Post>>(
      stream: fs.streamUserPosts(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final posts = snap.data ?? [];
        if (posts.isEmpty) {
          return const EmptyState(
            icon: Icons.note_add_rounded,
            title: "You haven't posted yet",
            message:
                'Lost something? Found something? Tap the + button to post.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: posts.length,
          itemBuilder: (_, i) => PostCard(post: posts[i]),
        );
      },
    );
  }
}
