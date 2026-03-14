import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/program_beneficiaries_record.dart';

class ProgramBeneficiariesService {
  static const String _collection = 'mapdata';

  static Future<(String docId, ProgramBeneficiariesRecord record)?> loadForProgram({
    required String programId,
  }) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection(_collection)
        .where('programId', isEqualTo: programId)
        .where('type', isEqualTo: 'beneficiaries')
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final docSnapshot = querySnapshot.docs.first;
    final record = ProgramBeneficiariesRecord.fromMap(
      Map<String, dynamic>.from(docSnapshot.data()),
    );
    return (docSnapshot.id, record);
  }

  static Future<void> save({
    required String? existingDocId,
    required ProgramBeneficiariesRecord record,
  }) async {
    final dataWithTimestamp = {
      ...record.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final collectionRef = FirebaseFirestore.instance.collection(_collection);

    if (existingDocId != null && existingDocId.isNotEmpty) {
      await collectionRef.doc(existingDocId).update(dataWithTimestamp);
      return;
    }

    await collectionRef.add(dataWithTimestamp);
  }
}
