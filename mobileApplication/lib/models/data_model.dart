class DataModel {
  DataModel(this.name, this.latitude, this.longitude, {this.value = 0});

  final String name;
  final double latitude;
  final double longitude;
  final double value; // Added value property for color mapping
}
