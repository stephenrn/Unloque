import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/models/organization_response_section.dart';
import 'package:unloque/models/program_form_field.dart';

class ProgramEditorService {
  static Future<List<ResponseSection>> loadDetailSections({
    required String organizationId,
    required String programId,
  }) async {
    final programDoc = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('programs')
        .doc(programId)
        .get();

    final data = programDoc.data();
    if (programDoc.exists && data != null && data['detailSections'] != null) {
      final detailsData = data['detailSections'] as List<dynamic>;
      return detailsData
          .whereType<Map>()
          .map((section) => ResponseSection.fromMap(
            Map<String, dynamic>.from(section),
          ))
          .toList(growable: false);
    }

        return const <ResponseSection>[];
  }

  static Future<List<ProgramFormField>> loadFormFields({
    required String organizationId,
    required String programId,
  }) async {
    final programDoc = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('programs')
        .doc(programId)
        .get();

    final data = programDoc.data();
    if (programDoc.exists && data != null && data['formFields'] != null) {
      final formFieldsData = data['formFields'] as List<dynamic>;
      return formFieldsData
          .whereType<Map>()
          .map((field) => ProgramFormField.fromMap(
                Map<String, dynamic>.from(field),
              ))
          .toList(growable: false);
    }

    return const <ProgramFormField>[];
  }

  static Future<void> updateProgram({
    required String organizationId,
    required String programId,
    required Map<String, dynamic> programData,
  }) async {
    final updateData = {
      ...programData,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('programs')
        .doc(programId)
        .update(updateData);
  }
}
