import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/db_service.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/status_badge.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_detail_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  Future<void> _launchDialer(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;

    final Uri uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch dialer';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to open phone dialer: $e'),
          ),
        );
      }
    }
  }

  Future<void> _markResolved(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as resolved?'),
        content: const Text(
            'This will mark the post as resolved and remove it from the active feed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, resolve'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DbService().markResolved(post.id);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post marked as resolved 🎉')),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete post?'),
        content:
            const Text('This cannot be undone. Are you sure you want to delete this post?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DbService().deletePost(post.id);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted')),
    );
  }

  Future<void> _messageUser(BuildContext context, {String? autoSendMessage}) async {
    try {
      final chatService = ChatService();
      final conversationId =
          await chatService.getOrCreateConversation(post.userId);
      if (autoSendMessage != null && autoSendMessage.isNotEmpty) {
        await chatService.sendMessage(
          conversationId: conversationId,
          content: autoSendMessage,
        );
      }
      final otherUser = await chatService.fetchOtherUser(post.userId);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserId: post.userId,
            otherUserName: otherUser?.name ?? post.userName,
            otherUserPhotoUrl: otherUser?.photoUrl ?? post.userPhotoUrl,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Could not start chat: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().supabaseUser?.id;
    final isOwner = uid == post.userId;
    final isLost = post.type == PostType.lost;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isLost ? AppColors.coral : AppColors.mint,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageSlider(
                imageUrls: post.imageUrls,
                isLost: isLost,
              ),
            ),
            actions: isOwner
                ? [
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.more_horiz_rounded,
                            color: Colors.white),
                      ),
                      onSelected: (v) {
                        if (v == 'delete') _delete(context);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete post'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ]
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(type: post.type, status: post.status),
                      const Spacer(),
                      Text(
                        DateHelpers.relative(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(post.title,
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sunny.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.category,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Description',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(post.description,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  _DetailTile(
                    icon: Icons.location_on_rounded,
                    title: isLost ? 'Last seen at' : 'Found at',
                    value: post.location,
                    color: AppColors.coral,
                  ),
                  _DetailTile(
                    leading: post.userPhotoUrl != null && post.userPhotoUrl!.isNotEmpty
                        ? Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.lavender.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: post.userPhotoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.lavender,
                                ),
                              ),
                            ),
                          )
                        : null,
                    icon: Icons.person_rounded,
                    title: 'Posted by',
                    value: post.userName,
                    color: AppColors.lavender,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileDetailScreen(userId: post.userId),
                        ),
                      );
                    },
                  ),
                  _DetailTile(
                    icon: Icons.call_rounded,
                    title: 'Contact',
                    value: post.contactInfo,
                    color: AppColors.mint,
                    copyable: true,
                    onTap: () => _launchDialer(context, post.contactInfo),
                  ),
                  _DetailTile(
                    icon: Icons.schedule_rounded,
                    title: 'Posted',
                    value: DateHelpers.full(post.createdAt),
                    color: AppColors.sunnyDark,
                  ),
                  const SizedBox(height: 24),

                  // ─── Action buttons ──────────────────────────────
                  if (isOwner && post.status == PostStatus.active)
                    GradientButton(
                      label: 'Mark as resolved',
                      icon: Icons.check_circle_rounded,
                      gradient: const LinearGradient(
                        colors: [AppColors.success, AppColors.mintDark],
                      ),
                      onPressed: () => _markResolved(context),
                    )
                  else if (!isOwner) ...[
                    // Message button — primary action
                    GradientButton(
                      label: 'Message ${post.userName.split(' ').first}',
                      icon: Icons.chat_bubble_rounded,
                      gradient: AppColors.primaryGradient,
                      onPressed: () => _messageUser(context),
                    ),
                    const SizedBox(height: 12),
                    // Claim button — secondary
                    GradientButton(
                      label: isLost
                          ? 'I found this item!'
                          : 'This is mine!',
                      icon: Icons.handshake_rounded,
                      gradient: isLost
                          ? AppColors.foundGradient
                          : AppColors.lostGradient,
                      onPressed: () => _messageUser(
                        context,
                        autoSendMessage: isLost
                            ? "Hi, I found your lost item: '${post.title}'!"
                            : "Hi, I believe the found item '${post.title}' is mine!",
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBg(bool isLost) => Container(
        decoration: BoxDecoration(
          gradient:
              isLost ? AppColors.lostGradient : AppColors.foundGradient,
        ),
        child: Center(
          child: Icon(
            isLost ? Icons.search_off_rounded : Icons.emoji_objects_rounded,
            size: 100,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      );
}

class _ImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final bool isLost;

  const _ImageSlider({required this.imageUrls, required this.isLost});

  @override
  State<_ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<_ImageSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _gradientBg(widget.isLost);
    }
    if (widget.imageUrls.length == 1) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrls.first,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _gradientBg(widget.isLost),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: widget.imageUrls[index],
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _gradientBg(widget.isLost),
            );
          },
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientBg(bool isLost) => Container(
        decoration: BoxDecoration(
          gradient:
              isLost ? AppColors.lostGradient : AppColors.foundGradient,
        ),
        child: Center(
          child: Icon(
            isLost ? Icons.search_off_rounded : Icons.emoji_objects_rounded,
            size: 100,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      );
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool copyable;
  final VoidCallback? onTap;
  final Widget? leading;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.copyable = false,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3F3A5C) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          leading ??
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onTap != null
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        decoration:
                            onTap != null ? TextDecoration.underline : null,
                      ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }
    return card;
  }
}


