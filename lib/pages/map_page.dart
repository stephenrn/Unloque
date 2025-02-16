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
  late List<_DataModel> _data;
  int _selectedIndex = -1;
  late MapZoomPanBehavior _zoomPanBehavior;

  List<_DataModel> _generateDataModel() {
    return <_DataModel>[
      _DataModel('Agdangan'),
      _DataModel('Alabat'),
      _DataModel('Atimonan'),
      _DataModel('Buenavista'),
      _DataModel('Burdeos'),
      _DataModel('Calauag'),
      _DataModel('Candelaria'),
      _DataModel('Catanauan'),
      _DataModel('Dolores'),
      _DataModel('General Luna'),
      _DataModel('General Nakar'),
      _DataModel('Guinayangan'),
      _DataModel('Gumaca'),
      _DataModel('Infanta'),
      _DataModel('Jomalig'),
      _DataModel('Lopez'),
      _DataModel('Lucban'),
      _DataModel('Lucena City'), // Updated name
      _DataModel('Macalelon'),
      _DataModel('Mauban'),
      _DataModel('Mulanay'),
      _DataModel('Padre Burgos'),
      _DataModel('Pagbilao'),
      _DataModel('Panukulan'),
      _DataModel('Patnanungan'),
      _DataModel('Perez'),
      _DataModel('Pitogo'),
      _DataModel('Plaridel'),
      _DataModel('Polillo'),
      _DataModel('Quezon'),
      _DataModel('Real'),
      _DataModel('Sampaloc'),
      _DataModel('San Andres'),
      _DataModel('San Antonio'),
      _DataModel('San Francisco'),
      _DataModel('San Narciso'),
      _DataModel('Sariaya'),
      _DataModel('Tagkawayan'),
      _DataModel('Tayabas City'),
      _DataModel('Tiaong'),
      _DataModel('Unisan'),
    ];
  }

  @override
  void initState() {
    _zoomPanBehavior = MapZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      enableDoubleTapZooming: true,
      zoomLevel: 1, // Initial zoom level
      minZoomLevel: 1,
      maxZoomLevel: 10,
    );
    super.initState();
    _data = _generateDataModel();
    _shapeSource = MapShapeSource.asset(
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
              color: Colors.blue, // Set the color to blue
              strokeColor: Colors.white, // Set the stroke color to white
              strokeWidth: 1,
              selectedIndex: _selectedIndex,
              selectionSettings: const MapSelectionSettings(
                  color: Color.fromRGBO(247, 87, 199, 1),
                  strokeColor: Colors.white,
                  strokeWidth: 1),
              zoomPanBehavior: _zoomPanBehavior,
              onSelectionChanged: (int index) {
                debugPrint('Shape selected: $index');
                setState(() {
                  if (index != _selectedIndex) {
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
                                  Text(_data[index].name, // Display the name
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
                                        )),
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
                    _selectedIndex = -1; // Reset the selected index
                    _selectedIndex = index; // Set the new selected index
                  } else {
                    _selectedIndex = -1;
                  }
                  debugPrint('Updated selectedIndex: $_selectedIndex');
                });
                debugPrint('onSelectionChanged completed');
              },
            )
          ],
        ),
      ),
    );
  }
}

class _DataModel {
  _DataModel(this.name);
  final String name;
}