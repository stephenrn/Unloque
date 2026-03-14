import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unloque/services/map/program_beneficiaries_service.dart';

import 'package:unloque/models/program_beneficiaries_record.dart';

class ProgramBeneficiariesEditor extends StatefulWidget {
  final String programId;
  final String programName;
  final String organizationId;

  const ProgramBeneficiariesEditor({
    Key? key,
    required this.programId,
    required this.programName,
    required this.organizationId,
  }) : super(key: key);

  @override
  ProgramBeneficiariesEditorState createState() =>
      ProgramBeneficiariesEditorState();
}

class ProgramBeneficiariesEditorState
    extends State<ProgramBeneficiariesEditor> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  bool _dataLoaded = false;
  String? _existingDocId;

  // List of municipalities in Quezon
  final List<String> municipalities = [
    'Total Beneficiaries',
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

  // Load existing beneficiary data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entry = await ProgramBeneficiariesService.loadForProgram(
        programId: widget.programId,
      );

      if (entry != null) {
        _existingDocId = entry.$1;
        final record = entry.$2;

        for (final municipality in municipalities) {
          if (municipality == 'Total Beneficiaries') {
            _controllers[municipality]!.text = record.totalBeneficiaries.toString();
            continue;
          }

          final value = record.municipalityCounts[municipality];
          if (value != null) {
            _controllers[municipality]!.text = value.toString();
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

  // Save beneficiary data to Firestore
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare data for saving
      final municipalityCounts = <String, int>{};
      int totalBeneficiaries = 0;

      for (String municipality in municipalities) {
        if (_controllers[municipality]!.text.isNotEmpty) {
          final parsed = int.parse(_controllers[municipality]!.text);
          if (municipality == 'Total Beneficiaries') {
            totalBeneficiaries = parsed;
          } else {
            municipalityCounts[municipality] = parsed;
          }
        }
      }

      final record = ProgramBeneficiariesRecord(
        programId: widget.programId,
        programName: widget.programName,
        organizationId: widget.organizationId,
        type: ProgramBeneficiariesRecord.typeBeneficiaries,
        title: '${widget.programName} Beneficiaries',
        totalBeneficiaries: totalBeneficiaries,
        municipalityCounts: municipalityCounts,
      );

      await ProgramBeneficiariesService.save(
        existingDocId: _existingDocId,
        record: record,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beneficiary data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Return to previous page after successful save
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
        title: Text(
          '${widget.programName} - Beneficiaries Editor',
          style: const TextStyle(color: Colors.white),
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
                                  'Program Beneficiaries Editor',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter the number of beneficiaries for each municipality in Quezon Province.',
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

                  // Beneficiaries fields in a scrollable list with grid layout
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

                        // Special styling for Total Beneficiaries (full width)
                        bool isTotal = municipality == 'Total Beneficiaries';

                        if (isTotal) {
                          return GridView.count(
                            crossAxisCount: 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              Card(
                                elevation: 2,
                                color: Colors.green[50],
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
                                          color: Colors.green[800],
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
                                      hintText: 'Beneficiaries',
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
