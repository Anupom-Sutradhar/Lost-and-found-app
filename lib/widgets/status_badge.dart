import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../config/theme.dart';


class StatusBadge extends StatelessWidget {
  final PostType type;
  final PostStatus status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.type,
    this.status = PostStatus.active,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = status == PostStatus.resolved;
    final gradient = isResolved
        ? const LinearGradient(
            colors: [AppColors.slate, AppColors.slateLight],
          )
        : (type == PostType.lost
            ? AppColors.lostGradient
            : AppColors.foundGradient);

    final label = isResolved ? 'RESOLVED' : type.label.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isResolved
                ? Icons.check_circle
                : (type == PostType.lost
                    ? Icons.search_rounded
                    : Icons.celebration_rounded),
            color: Colors.white,
            size: fontSize + 3,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
