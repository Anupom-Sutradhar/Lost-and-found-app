import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../config/constants.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/post_model.dart';
import '../utils/date_helpers.dart';
import 'status_badge.dart';


class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLost = post.type == PostType.lost;
    final accent = isLost ? AppColors.coral : AppColors.mint;

    return GestureDetector(
      onTap: onTap ??
          () => Navigator.pushNamed(context, AppRoutes.postDetail,
              arguments: post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(context),
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                        const SizedBox(height: 12),
                        Text(
                          post.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 16, color: AppColors.slateLight),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.location,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(label: post.category),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Diagonal ribbon — the signature visual.
              Positioned(
                top: -2,
                left: -2,
                child: _Ribbon(isLost: isLost),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final urls = post.imageUrls;
    if (urls.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: post.type == PostType.lost
              ? AppColors.lostGradient
              : AppColors.foundGradient,
        ),
        child: Icon(
          post.type == PostType.lost
              ? Icons.search_off_rounded
              : Icons.emoji_objects_rounded,
          size: 60,
          color: Colors.white.withOpacity(0.6),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: urls.first,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1B33)
            : AppColors.border,
        highlightColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2D2A4A)
            : AppColors.creamSoft,
        child: Container(
          height: 180,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        height: 180,
        color: AppColors.border,
        child: const Icon(Icons.broken_image, color: AppColors.slate),
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  final bool isLost;
  const _Ribbon({required this.isLost});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 64),
      painter: _RibbonPainter(isLost: isLost),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final bool isLost;
  _RibbonPainter({required this.isLost});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = (isLost ? AppColors.lostGradient : AppColors.foundGradient)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sunny.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.sunny
                  : AppColors.sunnyDark,
            ),
      ),
    );
  }
}
