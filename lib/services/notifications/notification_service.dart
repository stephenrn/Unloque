import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Stream<QuerySnapshot<Map<String, dynamic>>> notificationsStream({
    required String uid,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> unreadNotificationsStream({
    required String uid,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  static Future<void> markAllAsRead({required String uid}) async {
    // Get all unread notifications
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    // Create a batch to update all notifications at once
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  static Future<void> markAsRead({
    required String uid,
    required String notificationId,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  static Future<void> deleteNotification({
    required String uid,
    required String notificationId,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}
