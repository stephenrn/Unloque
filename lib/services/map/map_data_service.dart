import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/program_beneficiaries_record.dart';

class MapDataService {
  static Stream<QuerySnapshot<Map<String, dynamic>>> beneficiaryDocsStream() {
    return FirebaseFirestore.instance
        .collection('mapdata')
        .where('type', isEqualTo: 'beneficiaries')
        .snapshots();
  }

  static Future<Map<String, String>> fetchProgramCategories() async {
    final programCategories = <String, String>{};

    final orgSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .get();

    for (final orgDoc in orgSnapshot.docs) {
      final programsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgDoc.id)
          .collection('programs')
          .get();

      for (final programDoc in programsSnapshot.docs) {
        final data = programDoc.data();
        final programId = data['id'] as String?;
        final category = data['category'] as String?;

        if (programId != null && category != null) {
          programCategories[programId] = category;
        }
      }
    }

    return programCategories;
  }

  static Future<List<ProgramBeneficiariesRecord>> fetchBeneficiaryRecords() async {
    final beneficiarySnapshot = await FirebaseFirestore.instance
        .collection('mapdata')
        .where('type', isEqualTo: 'beneficiaries')
        .get();

    return beneficiarySnapshot.docs
        .map((d) => ProgramBeneficiariesRecord.fromMap(
              Map<String, dynamic>.from(d.data()),
            ))
        .toList();
  }
}
