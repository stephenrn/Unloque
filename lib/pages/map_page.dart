import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class MapPage extends StatefulWidget {
  MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  _MapPageState();
  late MapShapeSource _shapeSource;
  late MapShapeSource _sublayerSource;
  late List<_DataModel> _data;
  int _selectedIndex = -1;
  int _selectedSublayerIndex = -1;
  late MapZoomPanBehavior _zoomPanBehavior;

  List<_DataModel> _generateDataModel() {
    return <_DataModel>[
      _DataModel('Agdangan', 13.885378, 121.9359),
      _DataModel('Alabat', 14.1017, 122.0184),
      _DataModel('Atimonan', 14.0048, 121.9199),
      _DataModel('Buenavista', 13.7087, 122.4635),
      _DataModel('Burdeos', 14.7446, 121.9262),
      _DataModel('Calauag', 13.9547, 122.2872),
      _DataModel('Candelaria', 13.9311, 121.4233),
      _DataModel('Catanauan', 13.5927, 122.3208),
      _DataModel('Dolores', 14.0244, 121.3681),
      _DataModel('General Luna', 13.8425, 122.1494),
      _DataModel('General Nakar', 14.7631, 121.6349),
      _DataModel('Guinayangan', 13.9039, 122.4467),
      _DataModel('Gumaca', 13.9208, 122.1000),
      _DataModel('Infanta', 14.7425, 121.6494),
      _DataModel('Jomalig', 14.7131, 122.3677),
      _DataModel('Lopez', 13.8881, 122.2608),
      _DataModel('Lucban', 14.1114, 121.5575),
      _DataModel('Lucena City', 13.9419, 121.6169),
      _DataModel('Macalelon', 13.7458, 122.1294),
      _DataModel('Mauban', 14.1911, 121.7308),
      _DataModel('Mulanay', 13.5264, 122.4044),
      _DataModel('Padre Burgos', 13.9222, 121.8125),
      _DataModel('Pagbilao', 13.9789, 121.7119),
      _DataModel('Panukulan', 14.7472, 121.8139),
      _DataModel('Patnanungan', 14.7481, 122.1736),
      _DataModel('Perez', 14.1944, 121.9394),
      _DataModel('Pitogo', 13.7972, 122.0936),
      _DataModel('Plaridel', 13.9392, 122.0212),
      _DataModel('Polillo', 14.7111, 121.9556),
      _DataModel('Quezon', 14.0314, 122.1131),
      _DataModel('Real', 14.6647, 121.6081),
      _DataModel('Sampaloc', 14.1774, 121.6169),
      _DataModel('San Andres', 13.3252, 122.6504),
      _DataModel('San Antonio', 13.8951, 121.2970),
      _DataModel('San Francisco', 13.3471, 122.5202),
      _DataModel('San Narciso', 13.5689, 122.5662),
      _DataModel('Sariaya', 13.9633, 121.5253),
      _DataModel('Tagkawayan', 13.9647, 122.5472),
      _DataModel('Tayabas City', 14.0244, 121.5847),
      _DataModel('Tiaong', 13.9500, 121.3167),
      _DataModel('Unisan', 13.8558, 121.9686),
    ];
  }

  @override
  void initState() {
    _zoomPanBehavior = MapZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      enableDoubleTapZooming: true,
      zoomLevel: 5, // Increased initial zoom level
      minZoomLevel: 1,
      maxZoomLevel: 10,
      focalLatLng: MapLatLng(14.2347, 121.9473), // Centered on Quezon province
    );
    super.initState();
    _data = _generateDataModel();
    _shapeSource = MapShapeSource.asset(
      'lib/map/PHGeoJSON.json',
      shapeDataField: 'NAME_2',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].name,
    );
    _sublayerSource = MapShapeSource.asset(
      'lib/map/GeoJSON.json',
      shapeDataField: 'NAME_2',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].name,
    );
    debugPrint('MapShapeSource initialized');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MapPage with selectedIndex: $_selectedIndex');
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SfMaps(
          layers: [
            MapShapeLayer(
              loadingBuilder: (BuildContext context) {
                return const SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                );
              },
              source: _shapeSource,
              color: const Color.fromARGB(255, 218, 216, 216), // Set the color to blue
              strokeColor: Colors.white, // Set the stroke color to white
              strokeWidth: 1,
              selectedIndex: _selectedIndex,
              selectionSettings: const MapSelectionSettings(
                  color: Color.fromRGBO(87, 247, 212, 1),
                  strokeColor: Colors.white,
                  strokeWidth: 1),
              zoomPanBehavior: _zoomPanBehavior,
              onSelectionChanged: (int index) {
                setState(() {
                  if (index != _selectedIndex) {
                    _selectedIndex = -1;
                    _selectedIndex = index;
                  } else {
                    _selectedIndex = -1;
                  }
                });
              },
              sublayers: [
                MapShapeSublayer(
                  source: _sublayerSource,
                  color: const Color.fromARGB(255, 156, 156, 156), // Solid red default color
                  strokeColor: const Color.fromARGB(255, 201, 201, 201),
                  strokeWidth: 1,
                  selectedIndex: _selectedSublayerIndex,
                  selectionSettings: const MapSelectionSettings(
                    color: Color.fromARGB(255, 116, 92, 255),
                    strokeColor: Color.fromARGB(255, 0, 0, 0),
                    strokeWidth: 1
                  ),
                  onSelectionChanged: (int index) {
                    _zoomPanBehavior.focalLatLng = MapLatLng(
                      _data[index].latitude,
                      _data[index].longitude
                    );
                    _zoomPanBehavior.zoomLevel = 9;
                    
                    setState(() {
                      if (index != _selectedSublayerIndex) {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.blue,
                          duration: const Duration(seconds: 3),
                          content: Container(
                            height: 100,
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(_data[index].name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: () {
                                              ScaffoldMessenger.of(context)
                                                  .removeCurrentSnackBar();
                                            },
                                            child: const Icon(Icons.close,
                                                color: Colors.white),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: <Widget>[
                                      Text("hello",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.white))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                        _selectedSublayerIndex = -1;
                        _selectedSublayerIndex = index;
                      } else {
                        _selectedSublayerIndex = -1;
                      }
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _DataModel {
  _DataModel(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude;
  final double longitude;
}