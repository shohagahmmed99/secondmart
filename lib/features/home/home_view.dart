import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:second_mart/features/profile/user_details_view.dart';
import 'package:second_mart/features/notification/notification_service.dart';
import 'package:second_mart/features/widgets/expandable_text.dart';
import 'package:second_mart/features/home/widgets/comment_sheet.dart';
import 'package:second_mart/features/widgets/post_image_grid.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final Map<String, Map<String, String?>> _userDataCache = {};

  Future<Map<String, String?>> _fetchUserInfo(String uid) async {
    if (uid.isEmpty || uid == 'anonymous') {
      return {'name': 'Anonymous', 'profilePic': null};
    }
    if (_userDataCache.containsKey(uid)) return _userDataCache[uid]!;

    try {
      final ref = FirebaseDatabase.instance.ref('users');
      final snapshot = await ref.child(uid).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final name = data['name']?.toString() ?? 'User';
        final profilePic = data['profilePic']?.toString();
        final userInfo = {'name': name, 'profilePic': profilePic};
        _userDataCache[uid] = userInfo;
        return userInfo;
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
    return {'name': 'User', 'profilePic': null};
  }

  Future<void> _toggleLike(String postId, Map<dynamic, dynamic>? likes, String ownerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('posts/$postId/likes/${user.uid}');
    if (likes != null && likes.containsKey(user.uid)) {
      await ref.remove();
    } else {
      await ref.set(true);
      await NotificationService.sendNotification(
        receiverId: ownerId,
        type: 'like',
        postId: postId,
      );
      if (user.uid == ownerId && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.thumb_up, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text("You liked your own post."),
              ],
            ),
            backgroundColor: const Color(0xFF3498DB),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showComments(String postId, {required String postOwnerId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        postId: postId,
        postOwnerId: postOwnerId,
        fetchUserInfo: _fetchUserInfo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          "Second Mart",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('posts').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No posts found."));
          }

          final Map<dynamic, dynamic> postsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> posts = postsMap.entries.map((e) {
            final map = Map<String, dynamic>.from(e.value as Map);
            map['key'] = e.key;
            return map;
          }).toList();

          posts.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) => _buildPostCard(posts[index]),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'No Title';
    final price = data['price']?.toString() ?? '0.00';
    final condition = data['condition'] ?? 'Unknown Condition';
    final description = data['description'] ?? '';
    final userId = data['userId'] ?? '';
    final postId = data['key'] ?? '';
    final createdAt = data['createdAt'];

    final List<String> postImages = [];
    if (data['images'] != null && data['images'] is List) {
      postImages.addAll((data['images'] as List).map((e) => e.toString()));
    }

    final user = FirebaseAuth.instance.currentUser;
    final Map<dynamic, dynamic>? likes = data['likes'] != null ? Map<dynamic, dynamic>.from(data['likes'] as Map) : null;
    final isLiked = user != null && likes != null && likes.containsKey(user.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: FutureBuilder<Map<String, String?>>(
              future: _fetchUserInfo(userId),
              builder: (context, userSnap) {
                final name = userSnap.data?['name'] ?? 'User';
                final pic = userSnap.data?['profilePic'];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailsView(uid: userId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: pic != null ? NetworkImage(pic) : null,
                        child: pic == null ? Text(name[0]) : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${_getTimeAgo(createdAt as int?)} • Public", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Price: \$$price", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text("Condition: $condition"),
                const SizedBox(height: 8),
                if (description.isNotEmpty) ExpandableText(text: description),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (postImages.isNotEmpty) PostImageGrid(imageUrls: postImages),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                if (likes != null && likes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.thumb_up, color: Colors.white, size: 12),
                  ),
                  const SizedBox(width: 4),
                  Text("${likes.length}", style: TextStyle(color: Colors.grey[600])),
                ],
                const Spacer(),
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('comments/$postId').onValue,
                  builder: (context, commentSnap) {
                    final cData = commentSnap.data?.snapshot.value as Map?;
                    final cCount = cData?.length ?? 0;
                    return Text("$cCount comments", style: TextStyle(color: Colors.grey[600]));
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, 
                "Like", 
                color: isLiked ? Colors.blue : Colors.grey[700],
                onTap: () => _toggleLike(postId, likes, userId)
              ),
              _buildActionButton(Icons.chat_bubble_outline, "Comment", onTap: () => _showComments(postId, postOwnerId: userId)),
              _buildActionButton(Icons.share_outlined, "Share", onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String text, {Color? color, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color ?? Colors.grey[700]),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(color: color ?? Colors.grey[700], fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }
}
