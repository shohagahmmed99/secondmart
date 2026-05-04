import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:second_mart/features/notification/notification_service.dart';

class CommentSheet extends StatelessWidget {
  final String postId;
  final String postOwnerId;
  final Future<Map<String, String?>> Function(String) fetchUserInfo;

  const CommentSheet({
    super.key,
    required this.postId,
    required this.postOwnerId,
    required this.fetchUserInfo,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Comments",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance
                    .ref('comments/$postId')
                    .onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data?.snapshot.value == null) {
                    return const Center(child: Text("No comments yet."));
                  }
                  final data = Map<dynamic, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  final comments = data.entries.toList()
                    ..sort((a, b) {
                      final aTime = a.value['createdAt'] ?? 0;
                      final bTime = b.value['createdAt'] ?? 0;
                      return (bTime as int).compareTo(aTime as int);
                    });

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index].value;
                      final commenterId = comment['uid'] ?? '';
                      final text = comment['text'] ?? '';
                      
                      return FutureBuilder<Map<String, String?>>(
                        future: fetchUserInfo(commenterId),
                        builder: (context, userSnap) {
                          final name = userSnap.data?['name'] ?? 'User';
                          final pic = userSnap.data?['profilePic'];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundImage: pic != null ? NetworkImage(pic) : null,
                              child: pic == null ? Text(name[0], style: const TextStyle(fontSize: 12)) : null,
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(text),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            _CommentInputWidget(postId: postId, postOwnerId: postOwnerId),
          ],
        ),
      ),
    );
  }
}

class _CommentInputWidget extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  const _CommentInputWidget({required this.postId, required this.postOwnerId});

  @override
  State<_CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<_CommentInputWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Write a comment...",
                fillColor: Colors.grey[200],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () async {
              final text = _controller.text.trim();
              if (text.isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              await FirebaseDatabase.instance
                  .ref('comments/${widget.postId}')
                  .push()
                  .set({
                    'uid': user.uid,
                    'text': text,
                    'createdAt': ServerValue.timestamp,
                  });

              final sent = await NotificationService.sendNotification(
                receiverId: widget.postOwnerId,
                type: 'comment',
                postId: widget.postId,
                commentText: text,
              );

              _controller.clear();
              
              if (user.uid == widget.postOwnerId && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.chat_bubble, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text("You commented on your own post."),
                      ],
                    ),
                    backgroundColor: const Color(0xFF6C63FF),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
