import 'package:cloud_firestore/cloud_firestore.dart';

class QuezonPopulationService {
  static const String _collection = 'mapdata';
  static const String _docId = 'quezon_population';

  static Future<Map<String, int>> load() async {
    final docSnapshot =
        await FirebaseFirestore.instance.collection(_collection).doc(_docId).get();

    if (!docSnapshot.exists) return <String, int>{};

    final data = docSnapshot.data();
    if (data == null) return <String, int>{};

    final result = <String, int>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is num) {
        result[entry.key] = value.toInt();
      }
    }
    return result;
  }

  static Future<void> save({
    required Map<String, int> populationData,
  }) async {
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(_docId)
        .set(populationData, SetOptions(merge: true));
  }
}
