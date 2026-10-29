import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../services/db_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _fs = DbService();
  Timer? _debounce;

  List<Post> _results = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(value));
  }

  Future<void> _doSearch(String value) async {
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    setState(() => _searching = true);
    final hits = await _fs.searchPosts(q);
    if (!mounted) return;
    setState(() {
      _results = hits;
      _searching = false;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: false,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by item name...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.coral),
                    suffixIcon: _ctrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _ctrl.clear();
                              _onChanged('');
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searching
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.coral),
                )
              : !_searched
                  ? const EmptyState(
                      icon: Icons.travel_explore_rounded,
                      title: 'Search lost & found',
                      message:
                          'Type an item name like "wallet", "phone", "id card"...',
                    )
                  : _results.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matches',
                          message:
                              'Nothing found for "${_ctrl.text}". Try a different keyword.',
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: _results.length,
                          itemBuilder: (_, i) =>
                              PostCard(post: _results[i]),
                        ),
        ),
      ],
    );
  }
}
