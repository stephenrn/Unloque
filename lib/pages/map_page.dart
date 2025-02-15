import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class MapPage extends StatefulWidget {
  MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late MapShapeSource _shapeSource;

  @override
  void initState() {
    super.initState();
    _shapeSource = MapShapeSource.asset(
      'lib/map/GeoJSON.json',
      shapeDataField: 'NAME_2',
    );
    debugPrint('MapShapeSource initialized');
  }

  void _showShapeDetails(String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('City Details'),
          content: Text('City: $name'),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MapPage');
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SfMaps(
          layers: [
            MapShapeLayer(
              source: _shapeSource,
              color: Colors.blue,
              shapeTooltipBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'City: ${_shapeSource.primaryValueMapper!(index)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
              strokeColor: Colors.black,
              legend: MapLegend(
                MapElement.shape,
                enableToggleInteraction: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
