import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chat_service.dart';
import 'chat_detail_view.dart';

class MessageView extends StatefulWidget {
  const MessageView({super.key});

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
  final Map<String, Map<String, String?>> _userCache = {};
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

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
      debugPrint('Error fetching user for inbox: $e');
    }
    return {'name': 'User', 'profilePic': null};
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final h = hour % 12 == 0 ? 12 : hour % 12;
      return '$h:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Spacer(),

                  // Edit / compose icon
                  _HeaderIconButton(icon: Icons.edit_outlined, onTap: () {}),
                  const SizedBox(width: 4),
                  // Search icon
                  _HeaderIconButton(icon: Icons.search, onTap: () {}),
                ],
              ),
            ),

            // ── Active Users Row ─────────────────────────────────────
            _ActiveUsersRow(fetchUser: _fetchUser, currentUid: _currentUid),

            Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFFE0E0E0),
            ),

            // ── Chat List ────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: ChatService.getUserChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data?.snapshot.value == null) {
                    return _buildEmptyState();
                  }

                  final data = Map<dynamic, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  final chats = data.values.toList()
                    ..sort(
                      (a, b) => (b['timestamp'] as int).compareTo(
                        a['timestamp'] as int,
                      ),
                    );

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final otherUserId = chat['otherUserId'];
                      final lastMsg = chat['lastMessage'] ?? '';
                      final timestamp = chat['timestamp'];
                      final unreadCount = chat['unreadCount'] as int? ?? 0;
                      final isUnread = unreadCount > 0;

                      return FutureBuilder<Map<String, String?>>(
                        future: _fetchUser(otherUserId),
                        builder: (context, userSnap) {
                          final name = userSnap.data?['name'] ?? 'User';
                          final pic = userSnap.data?['profilePic'];

                          return _ChatTile(
                            name: name,
                            profilePic: pic,
                            lastMessage: lastMsg,
                            time: _formatTime(timestamp as int?),
                            isUnread: isUnread,
                            unreadCount: unreadCount,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailView(
                                    otherUserId: otherUserId,
                                    otherUserName: name,
                                    otherUserProfilePic: pic,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    /*    

      // ── Floating Action Button (New chat) ────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0084FF),
        elevation: 4,
        onPressed: () {},
        child: const Icon(Icons.edit, color: Colors.white),
      ),
   */
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start chatting with sellers or buyers!",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header icon button (circle grey background)
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFF0F0F0),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active users story-style row (like Messenger)
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveUsersRow extends StatefulWidget {
  final Future<Map<String, String?>> Function(String uid) fetchUser;
  final String? currentUid;

  const _ActiveUsersRow({required this.fetchUser, required this.currentUid});

  @override
  State<_ActiveUsersRow> createState() => _ActiveUsersRowState();
}

class _ActiveUsersRowState extends State<_ActiveUsersRow> {
  List<Map<String, dynamic>> _activeUsers = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadActiveUsers();
  }

  Future<void> _loadActiveUsers() async {
    final uid = widget.currentUid;
    if (uid == null) return;

    try {
      final snap = await FirebaseDatabase.instance.ref('user_chats/$uid').get();
      if (!snap.exists || snap.value == null) return;

      final data = Map<dynamic, dynamic>.from(snap.value as Map);
      final List<Map<String, dynamic>> users = [];

      for (final entry in data.entries) {
        final otherUid = entry.key.toString();
        final info = await widget.fetchUser(otherUid);
        users.add({
          'uid': otherUid,
          'name': info['name'] ?? 'User',
          'profilePic': info['profilePic'],
        });
        if (users.length >= 8) break; // limit to 8 in the row
      }

      if (mounted) {
        setState(() {
          _activeUsers = users;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading active users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded && _activeUsers.isEmpty) {
      return const SizedBox(height: 100);
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _activeUsers.length,
        itemBuilder: (context, index) {
          final user = _activeUsers[index];
          final name = user['name'] as String;
          final pic = user['profilePic'] as String?;
          final shortName = name.split(' ').first.length > 8
              ? '${name.split(' ').first.substring(0, 7)}…'
              : name.split(' ').first;

          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0084FF),
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: pic != null ? NetworkImage(pic) : null,
                        backgroundColor: Colors.grey[200],
                        child: pic == null
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0084FF),
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Online indicator dot
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF44C64C),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  shortName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single chat list tile — Messenger style
// ─────────────────────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String name;
  final String? profilePic;
  final String lastMessage;
  final String time;
  final bool isUnread;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.profilePic,
    required this.lastMessage,
    required this.time,
    required this.isUnread,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: profilePic != null
                      ? NetworkImage(profilePic!)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: profilePic == null
                      ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0084FF),
                          ),
                        )
                      : null,
                ),
                // Online dot on avatar
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF44C64C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[500],
                      fontWeight: isUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Time + unread badge
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread
                        ? const Color(0xFF0084FF)
                        : Colors.grey[400],
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                if (isUnread)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0084FF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  // Blue double-tick for read messages
                  const Icon(
                    Icons.done_all,
                    size: 16,
                    color: Color(0xFF0084FF),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
