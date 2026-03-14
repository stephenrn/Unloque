class ProgramBeneficiariesRecord {
  static const String typeBeneficiaries = 'beneficiaries';

  final String programId;
  final String programName;
  final String organizationId;
  final String type;
  final String title;
  final int totalBeneficiaries;
  final Map<String, int> municipalityCounts;

  const ProgramBeneficiariesRecord({
    required this.programId,
    required this.programName,
    required this.organizationId,
    required this.type,
    required this.title,
    required this.totalBeneficiaries,
    required this.municipalityCounts,
  });

  factory ProgramBeneficiariesRecord.fromMap(Map<String, dynamic> map) {
    final totalBeneficiaries = (map['Total Beneficiaries'] as num?)?.toInt() ?? 0;

    const excludedKeys = <String>{
      'programId',
      'programName',
      'organizationId',
      'type',
      'title',
      'Total Beneficiaries',
      'updatedAt',
      'createdAt',
    };

    final municipalityCounts = <String, int>{};
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      if (excludedKeys.contains(key)) continue;
      if (value is num) {
        municipalityCounts[key] = value.toInt();
      }
    }

    return ProgramBeneficiariesRecord(
      programId: (map['programId'] ?? '').toString(),
      programName: (map['programName'] ?? '').toString(),
      organizationId: (map['organizationId'] ?? '').toString(),
      type: (map['type'] ?? typeBeneficiaries).toString(),
      title: (map['title'] ?? '').toString(),
      totalBeneficiaries: totalBeneficiaries,
      municipalityCounts: municipalityCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'programId': programId,
      'programName': programName,
      'organizationId': organizationId,
      'type': type,
      'title': title,
      'Total Beneficiaries': totalBeneficiaries,
      ...municipalityCounts,
    };
  }
}
