import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:second_mart/features/notification/notification_service.dart';

class ChatService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  static Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final chatId = getChatId(currentUserId, receiverId);
    final timestamp = ServerValue.timestamp;

    // 1. Add message to the chat
    final messageRef = _db.ref('chats/$chatId/messages').push();
    await messageRef.set({
      'senderId': currentUserId,
      'text': text,
      'timestamp': timestamp,
    });

    // 2. Update user_chats for both users (Inbox view)
    // For the sender: just update last message and timestamp
    await _db.ref('user_chats/$currentUserId/$receiverId').update({
      'chatId': chatId,
      'lastMessage': text,
      'timestamp': timestamp,
      'otherUserId': receiverId,
    });

    // For the receiver: update last message, timestamp, AND increment unreadCount
    final receiverChatRef = _db.ref('user_chats/$receiverId/$currentUserId');
    await receiverChatRef.runTransaction((Object? post) {
      if (post == null) {
        return Transaction.success({
          'chatId': chatId,
          'lastMessage': text,
          'timestamp': timestamp,
          'otherUserId': currentUserId,
          'unreadCount': 1,
        });
      }
      final Map<String, dynamic> chat = Map<String, dynamic>.from(post as Map);
      chat['lastMessage'] = text;
      chat['timestamp'] = timestamp;
      chat['unreadCount'] = (chat['unreadCount'] ?? 0) + 1;
      return Transaction.success(chat);
    });

    // 3. Send notification to the receiver
    await NotificationService.sendNotification(
      receiverId: receiverId,
      type: 'message',
      commentText: text,
      postId: '', // Reuse commentText field for the message preview
    );
  }

  static Future<void> markChatAsRead(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    await _db.ref('user_chats/$currentUserId/$otherUserId').update({
      'unreadCount': 0,
    });
  }

  static Stream<DatabaseEvent> getMessages(String chatId) {
    return _db.ref('chats/$chatId/messages').orderByChild('timestamp').onValue;
  }

  static Stream<DatabaseEvent> getUserChats() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('user_chats/$uid').orderByChild('timestamp').onValue;
  }
}
