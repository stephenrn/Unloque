class OrganizationInfo {
  final String id;
  final String name;
  final String logoUrl;

  const OrganizationInfo({
    required this.id,
    required this.name,
    required this.logoUrl,
  });

  factory OrganizationInfo.fromMap(String id, Map<String, dynamic> map) {
    return OrganizationInfo(
      id: id,
      name: (map['name'] ?? '').toString(),
      logoUrl: (map['logoUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
    };
  }
}
