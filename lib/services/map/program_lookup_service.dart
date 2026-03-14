import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/organization_info.dart';
import '../../models/program_info.dart';

class ProgramLookupService {
  static Future<ProgramInfo?> getProgramDetails(String programId) async {
    try {
      final programs = await FirebaseFirestore.instance
          .collectionGroup('programs')
          .where('id', isEqualTo: programId)
          .limit(1)
          .get();

      if (programs.docs.isNotEmpty) {
        return ProgramInfo.fromMap(programs.docs.first.data());
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<ProgramInfo?> getProgramDetailsFallback(
    String programId,
  ) async {
    try {
      final organizationsSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      for (final orgDoc in organizationsSnapshot.docs) {
        final programsSnapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgDoc.id)
            .collection('programs')
            .where('id', isEqualTo: programId)
            .limit(1)
            .get();

        if (programsSnapshot.docs.isNotEmpty) {
          return ProgramInfo.fromMap(programsSnapshot.docs.first.data());
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<OrganizationInfo?> getOrganizationDetails(
    String organizationId,
  ) async {
    if (organizationId.isEmpty) return null;

    try {
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (!orgDoc.exists) return null;

      final data = orgDoc.data();
      if (data == null) return null;
      return OrganizationInfo.fromMap(orgDoc.id, data);
    } catch (_) {
      return null;
    }
  }
}
