class MapLocation {
  const MapLocation(this.name, this.latitude, this.longitude, {this.value = 0});

  final String name;
  final double latitude;
  final double longitude;
  final double value;

  factory MapLocation.fromMap(Map<String, dynamic> map) {
    return MapLocation(
      (map['name'] ?? map['label'] ?? '').toString(),
      _doubleFromDynamic(map['latitude'] ?? map['lat']),
      _doubleFromDynamic(map['longitude'] ?? map['lng'] ?? map['lon']),
      value: _doubleFromDynamic(map['value'] ?? map['metric']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'value': value,
    };
  }

  MapLocation copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? value,
  }) {
    return MapLocation(
      name ?? this.name,
      latitude ?? this.latitude,
      longitude ?? this.longitude,
      value: value ?? this.value,
    );
  }

  static List<MapLocation> listFromDynamic(dynamic value) {
    if (value is! List) return <MapLocation>[];

    return value
        .whereType<Map>()
        .map((m) => MapLocation.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  static double _doubleFromDynamic(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) {
    return other is MapLocation &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(name, latitude, longitude, value);
}
