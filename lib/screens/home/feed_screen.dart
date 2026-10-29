import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../services/db_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _fs = DbService();
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _tab.index == 0;

    return Column(
      children: [
        // Tab bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3F3A5C)
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black12
                      : AppColors.navy.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                gradient: isLost
                    ? AppColors.lostGradient
                    : AppColors.foundGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isLost ? AppColors.coral : AppColors.mint)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.slate,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  GoogleFonts.poppins(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Lost', height: 48),
                Tab(text: 'Found', height: 48),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Category filter
        _CategoryFilter(
          selected: _category,
          onSelect: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: 8),
        // Posts list
        Expanded(
          child: StreamBuilder<List<Post>>(
            stream: _fs.streamPosts(
              type: isLost ? PostType.lost : PostType.found,
              status: PostStatus.active,
              category: _category == 'All' ? null : _category,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snap.hasError) {
                return EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Something went wrong',
                  message: snap.error.toString(),
                );
              }
              final posts = snap.data ?? [];
              if (posts.isEmpty) {
                return EmptyState(
                  icon: isLost ? Icons.search_off_rounded : Icons.inbox_rounded,
                  title: isLost
                      ? 'No lost items reported yet'
                      : 'No found items reported yet',
                  message: 'Tap the + button to post the first one.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: posts.length,
                itemBuilder: (_, i) => PostCard(post: posts[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cats = ['All', ...PostCategories.all];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = cats[i];
          final isSel = c == selected;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSel ? AppColors.primaryGradient : null,
                color: isSel ? null : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: isSel
                      ? Colors.transparent
                      : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF3F3A5C)
                          : AppColors.border),
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  c,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSel
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
