import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PopulationEditorPage extends StatefulWidget {
  const PopulationEditorPage({super.key});

  @override
  PopulationEditorPageState createState() => PopulationEditorPageState();
}

class PopulationEditorPageState extends State<PopulationEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  bool _dataLoaded = false;

  // List of municipalities in Quezon
  final List<String> municipalities = [
    'Total Population',
    'Agdangan',
    'Alabat',
    'Atimonan',
    'Buenavista',
    'Burdeos',
    'Calauag',
    'Candelaria',
    'Catanauan',
    'Dolores',
    'General Luna',
    'General Nakar',
    'Guinayangan',
    'Gumaca',
    'Infanta',
    'Jomalig',
    'Lopez',
    'Lucban',
    'Lucena City',
    'Macalelon',
    'Mauban',
    'Mulanay',
    'Padre Burgos',
    'Pagbilao',
    'Panukulan',
    'Patnanungan',
    'Perez',
    'Pitogo',
    'Plaridel',
    'Polillo',
    'Quezon',
    'Real',
    'Sampaloc',
    'San Andres',
    'San Antonio',
    'San Francisco',
    'San Narciso',
    'Sariaya',
    'Tagkawayan',
    'Tayabas City',
    'Tiaong',
    'Unisan'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers for each municipality
    for (String municipality in municipalities) {
      _controllers[municipality] = TextEditingController();
    }

    // Load existing data if available
    _loadData();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Load existing population data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('mapdata')
          .doc('quezon_population')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        for (String municipality in municipalities) {
          if (data.containsKey(municipality)) {
            _controllers[municipality]!.text = data[municipality].toString();
          }
        }
      }

      setState(() {
        _dataLoaded = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save population data to Firestore
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare data for saving
      Map<String, dynamic> populationData = {};
      for (String municipality in municipalities) {
        if (_controllers[municipality]!.text.isNotEmpty) {
          populationData[municipality] =
              int.parse(_controllers[municipality]!.text);
        }
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('mapdata')
          .doc('quezon_population')
          .set(populationData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Population data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Quezon Population Editor',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && !_dataLoaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header card with instructions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Population Data Editor',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter population values for each municipality in Quezon Province.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Population fields in a scrollable list with grid layout
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: municipalities.length,
                      itemBuilder: (context, index) {
                        final municipality = municipalities[index];

                        // Special styling for Total Population (full width)
                        bool isTotal = municipality == 'Total Population';

                        if (isTotal) {
                          return GridView.count(
                            crossAxisCount: 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              Card(
                                elevation: 2,
                                color: Colors.blue[50],
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        municipality,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                              _controllers[municipality],
                                          decoration: const InputDecoration(
                                            hintText: 'Enter total',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          style: const TextStyle(fontSize: 14),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Card(
                          elevation: 1,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  municipality,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: TextFormField(
                                    controller: _controllers[municipality],
                                    decoration: InputDecoration(
                                      hintText: 'Population',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...', style: TextStyle(fontSize: 14)),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'SAVE DATA',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
