class ProgramInfo {
  final String id;
  final String name;
  final String category;
  final String organizationId;

  const ProgramInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.organizationId,
  });

  factory ProgramInfo.fromMap(Map<String, dynamic> map) {
    return ProgramInfo(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      organizationId: (map['organizationId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'organizationId': organizationId,
    };
  }
}
