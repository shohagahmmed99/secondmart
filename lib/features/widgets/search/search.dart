import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:second_mart/features/profile/user_details_view.dart';

class Search extends SearchDelegate<String> {
  // Cache all posts fetched from Firebase
  List<Map<String, dynamic>> _allPosts = [];
  bool _fetched = false;

  // ── Override hint text ────────────────────────────────────────────────────
  @override
  String get searchFieldLabel => 'Search products, categories…';

  @override
  TextStyle get searchFieldStyle => const TextStyle(fontSize: 16);

  // ── Actions (clear button) ────────────────────────────────────────────────
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  // ── Leading (back button) ─────────────────────────────────────────────────
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
      onPressed: () => close(context, ''),
    );
  }

  // ── Results (shown after submitting) ─────────────────────────────────────
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchBody(context);
  }

  // ── Suggestions (shown while typing) ─────────────────────────────────────
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchBody(context);
  }

  // ── Core search body ──────────────────────────────────────────────────────
  Widget _buildSearchBody(BuildContext context) {
    if (query.trim().isEmpty) {
      return _buildEmptyQuery();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPosts(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = _filter(snap.data ?? []);

        if (results.isEmpty) {
          return _buildNoResults();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: results.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 80, endIndent: 16),
          itemBuilder: (context, index) =>
              _SearchResultTile(post: results[index]),
        );
      },
    );
  }

  // ── Fetch posts from Firebase (cached) ───────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    if (_fetched) return _allPosts;
    try {
      final snap =
          await FirebaseDatabase.instance.ref('posts').get();
      if (snap.exists && snap.value != null) {
        final raw = Map<dynamic, dynamic>.from(snap.value as Map);
        _allPosts = raw.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['key'] = e.key;
          return map;
        }).toList();
        _fetched = true;
      }
    } catch (e) {
      debugPrint('Search fetch error: $e');
    }
    return _allPosts;
  }

  // ── Filter posts by query ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> posts) {
    final q = query.trim().toLowerCase();
    return posts.where((p) {
      final title = (p['title'] ?? '').toString().toLowerCase();
      final desc = (p['description'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();
      final condition = (p['condition'] ?? '').toString().toLowerCase();
      final userName = (p['userName'] ?? '').toString().toLowerCase();
      return title.contains(q) ||
          desc.contains(q) ||
          category.contains(q) ||
          condition.contains(q) ||
          userName.contains(q);
    }).toList()
      ..sort((a, b) =>
          (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
  }

  // ── Empty state widgets ───────────────────────────────────────────────────
  Widget _buildEmptyQuery() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Search Second Mart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try "iPhone", "Electronics", "New"…',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different keyword or category',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single search result tile
// ─────────────────────────────────────────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> post;

  const _SearchResultTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final title = post['title'] ?? 'No Title';
    final price = post['price']?.toString() ?? '0';
    final category = post['category'] ?? '';
    final condition = post['condition'] ?? '';
    final userName = post['userName'] ?? 'User';
    final userId = post['userId'] ?? '';
    final images = post['images'];
    final String? firstImage =
        (images is List && images.isNotEmpty) ? images[0].toString() : null;

    return InkWell(
      onTap: () {
        // Navigate to the seller's profile / post detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailsView(uid: userId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // ── Thumbnail ────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: firstImage != null
                  ? Image.network(
                      firstImage,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),

            // ── Details ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$$price',
                    style: const TextStyle(
                      color: Color(0xFF27AE60),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (category.isNotEmpty) ...[
                        _Chip(label: category, color: const Color(0xFF3498DB)),
                        const SizedBox(width: 6),
                      ],
                      if (condition.isNotEmpty)
                        _Chip(label: condition, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Arrow ─────────────────────────────────────────────────────
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 62,
      height: 62,
      color: Colors.grey[200],
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 28),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small category / condition chip
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
