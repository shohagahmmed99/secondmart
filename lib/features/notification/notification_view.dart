import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'package:second_mart/features/home/post_detail_view.dart';
import 'package:second_mart/features/chat/chat_detail_view.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final Map<String, Map<String, String?>> _userCache = {};

  Future<Map<String, String?>> _fetchUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    try {
      final snap = await FirebaseDatabase.instance.ref('users/$uid').get();
      if (snap.exists) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        final info = {
          'name': data['name']?.toString() ?? 'User',
          'profilePic': data['profilePic']?.toString(),
        };
        _userCache[uid] = info;
        return info;
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
    return {'name': 'User', 'profilePic': null};
  }

  String _getNotificationText(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'like':
        return "liked your post.";
      case 'comment':
        return "commented: \"${data['commentText'] ?? ''}\"";
      case 'share':
        return "shared your post.";
      case 'message':
        return "sent you a message: \"${data['commentText'] ?? ''}\"";
      default:
        return "interacted with your post.";
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'share':
        return Icons.reply_all;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'like':
        return const Color(0xFFFF4B6E);
      case 'comment':
        return const Color(0xFF6C63FF);
      case 'share':
        return const Color(0xFF4CAF50);
      case 'message':
        return const Color(0xFF0084FF);
      default:
        return Colors.blueGrey;
    }
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

  bool _isToday(int? timestamp) {
    if (timestamp == null) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to see notifications.")),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Activity",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => NotificationService.markAllAsRead(user.uid),
            child: const Text(
              "Read all",
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: const Text(
                          "Clear all notifications",
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          NotificationService.clearAll(user.uid);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('notifications/${user.uid}')
            .orderByChild('timestamp')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return _buildEmptyState();
          }

          final data = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
          final items = data.entries.toList()
            ..sort(
              (a, b) => (b.value['timestamp'] as int).compareTo(
                a.value['timestamp'] as int,
              ),
            );

          final todayItems = items
              .where((e) => _isToday(e.value['timestamp']))
              .toList();
          final earlierItems = items
              .where((e) => !_isToday(e.value['timestamp']))
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (todayItems.isNotEmpty) ...[
                _buildSectionHeader("Today"),
                ...todayItems.map((e) => _buildNotificationItem(e, user.uid)),
              ],
              if (earlierItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader("Earlier"),
                ...earlierItems.map((e) => _buildNotificationItem(e, user.uid)),
              ],
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    MapEntry<dynamic, dynamic> entry,
    String userId,
  ) {
    final notif = Map<String, dynamic>.from(entry.value as Map);
    final isRead = notif['isRead'] ?? false;
    final senderId = notif['senderId'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<Map<String, String?>>(
        future: _fetchUser(senderId),
        builder: (context, userSnap) {
          final name = userSnap.data?['name'] ?? 'Someone';
          final pic = userSnap.data?['profilePic'];

          return InkWell(
            onTap: () {
              if (!isRead) {
                NotificationService.markAsRead(userId, entry.key.toString());
              }

              if (notif['type'] == 'message') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailView(
                      otherUserId: senderId,
                      otherUserName: name,
                      otherUserProfilePic: pic,
                    ),
                  ),
                );
                return;
              }

              final postId = notif['postId'];
              if (postId != null && postId.toString().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailView(postId: postId.toString()),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRead ? Theme.of(context).cardColor : const Color(0xFFEEEDFF).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 1.0),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isRead
                                ? Colors.grey[200]!
                                : const Color(0xFF6C63FF).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: pic != null
                              ? NetworkImage(pic)
                              : null,
                          child: pic == null
                              ? Text(
                                  name[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notif['type']),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _getNotificationIcon(notif['type']),
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: "$name ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: _getNotificationText(notif)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeAgo(notif['timestamp']),
                          style: TextStyle(
                            color: isRead
                                ? Colors.grey[500]
                                : const Color(0xFF6C63FF),
                            fontSize: 12,
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      margin: const EdgeInsets.only(top: 8, left: 8),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Quiet for now",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "When you get notifications, they'll show up here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
