import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Returns [true] if the notification was sent, [false] if skipped
  /// (e.g. the user is interacting with their own post, or an error occurred).
  static Future<bool> sendNotification({
    required String receiverId,
    required String type,
    required String postId,
    String? commentText,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('📬 sendNotification called: type=$type, receiverId=$receiverId, postId=$postId');

    if (currentUser == null) {
      debugPrint('❌ sendNotification: no logged-in user, aborting');
      return false;
    }
    /* 
    // Skip — user is interacting with their own post
    if (currentUser.uid == receiverId) {
      debugPrint('⚠️ sendNotification: user acted on their own post, skipping');
      return false;
    }
    */

    try {
      final ref = _db.ref('notifications/$receiverId').push();
      await ref.set({
        'senderId': currentUser.uid,
        'type': type,
        'postId': postId,
        'commentText': commentText,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
      });
      debugPrint('✅ Notification written to notifications/$receiverId/${ref.key}');
      return true;
    } catch (e) {
      debugPrint('❌ sendNotification write failed: $e');
      return false;
    }
  }
  static Future<void> markAllAsRead(String userId) async {
    final ref = _db.ref('notifications/$userId');
    final snap = await ref.get();
    if (snap.exists) {
      final data = Map<dynamic, dynamic>.from(snap.value as Map);
      final updates = <String, dynamic>{};
      for (var key in data.keys) {
        updates['$key/isRead'] = true;
      }
      await ref.update(updates);
    }
  }

  static Future<void> markAsRead(String userId, String notificationId) async {
    await _db.ref('notifications/$userId/$notificationId/isRead').set(true);
  }

  static Future<void> clearAll(String userId) async {
    await _db.ref('notifications/$userId').remove();
  }
}
