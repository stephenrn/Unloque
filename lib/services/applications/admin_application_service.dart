import 'package:cloud_firestore/cloud_firestore.dart';

class AdminApplicationService {
  static Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  static Future<List<Map<String, dynamic>>> fetchApplicationsForProgram({
    required List<QueryDocumentSnapshot<Object?>> users,
    required String programId,
  }) async {
    final List<Map<String, dynamic>> applications = [];

    for (final userDoc in users) {
      final userId = userDoc.id;
      final userData = (userDoc.data() as Map<String, dynamic>?) ?? const {};
      final userEmail = (userData['email'] ?? '').toString();

      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users-application')
          .where('id', isEqualTo: programId)
          .get();

      for (final doc in query.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['userId'] = userId;
        data['userEmail'] = userEmail;
        applications.add(data);
      }
    }

    return applications;
  }
}
