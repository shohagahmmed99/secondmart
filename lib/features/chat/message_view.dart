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
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ChatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return _buildEmptyState();
          }

          final data = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
          final chats = data.values.toList()
            ..sort(
              (a, b) =>
                  (b['timestamp'] as int).compareTo(a['timestamp'] as int),
            );

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat['otherUserId'];
              final lastMsg = chat['lastMessage'] ?? '';
              final timestamp = chat['timestamp'];

              return FutureBuilder<Map<String, String?>>(
                future: _fetchUser(otherUserId),
                builder: (context, userSnap) {
                  final name = userSnap.data?['name'] ?? 'User';
                  final pic = userSnap.data?['profilePic'];

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: pic != null ? NetworkImage(pic) : null,
                      child: pic == null
                          ? Text(name[0], style: const TextStyle(fontSize: 20))
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      _formatTime(timestamp as int?),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
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
    );
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
            style: TextStyle(color: Colors.grey[500], fontSize: 18),
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
