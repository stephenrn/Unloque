import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class PreviewFormsProgramPage extends StatefulWidget {
  final String organizationId;
  final String programId;
  final List<Map<String, dynamic>>? formFields;

  const PreviewFormsProgramPage({
    Key? key,
    required this.organizationId,
    required this.programId,
    this.formFields,
  }) : super(key: key);

  @override
  State<PreviewFormsProgramPage> createState() =>
      _PreviewFormsProgramPageState();
}

class _PreviewFormsProgramPageState extends State<PreviewFormsProgramPage> {
  bool _isLoading = true;
  Map<String, dynamic> _programData = {};
  Map<String, dynamic> _organizationData = {};
  List<Map<String, dynamic>> _formFields = [];

  // Form state variables
  Map<String, String?> _selectedOptions = {}; // field label -> selected option
  Map<String, Map<String, bool>> _checkboxValues =
      {}; // field label -> option -> bool
  Map<String, DateTime?> _selectedDates = {}; // For date selections
  Map<String, List<Map<String, dynamic>>> _attachedFilesMap =
      {}; // field label -> files
  Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load program data from Firebase first
      final programDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('programs')
          .doc(widget.programId)
          .get();

      if (programDoc.exists) {
        _programData = programDoc.data() ?? {};

        // Always prioritize form fields from Firebase
        if (_programData['formFields'] != null) {
          _formFields = List<Map<String, dynamic>>.from(
            _programData['formFields'] as List<dynamic>,
          );
        }
        // Use widget.formFields only if Firebase data is empty
        else if (widget.formFields != null && widget.formFields!.isNotEmpty) {
          _formFields = List<Map<String, dynamic>>.from(widget.formFields!);
        }
      } else {
        // If program doesn't exist in Firebase, use provided formFields as fallback
        if (widget.formFields != null && widget.formFields!.isNotEmpty) {
          _formFields = List<Map<String, dynamic>>.from(widget.formFields!);
        }
      }

      // Load organization data
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .get();

      if (orgDoc.exists) {
        _organizationData = orgDoc.data() ?? {};
      }

      // Initialize form state based on loaded form fields
      _initializeFormState();
    } catch (error) {
      print('Error loading preview data: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeFormState() {
    // Initialize controllers and state variables based on form fields
    for (var field in _formFields) {
      final type = field['type'];
      final label = field['label'];

      if (type == 'short_answer' || type == 'paragraph') {
        _textControllers[label] = TextEditingController();
      } else if (type == 'multiple_choice') {
        _selectedOptions[label] = null;
      } else if (type == 'checkbox' && field['options'] != null) {
        _checkboxValues[label] = {};
        for (var option in field['options'] as List) {
          _checkboxValues[label]![option.toString()] = false;
        }
      } else if (type == 'date') {
        _selectedDates[label] = null;
      } else if (type == 'attachment') {
        _attachedFilesMap[label] = [];
      }
    }
  }

  Future<void> _selectDate(BuildContext context, String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDates[label] = picked;
      });
    }
  }

  Color darkenColor(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  @override
  Widget build(BuildContext context) {
    // Get color from program data or default to blue
    final Color programColor = _programData['color'] != null
        ? Color(_programData['color'])
        : Colors.blue[200]!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
          child: Row(
            children: [
              // Back button
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: Transform.rotate(
                    angle: 4.71239,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Page title
              Expanded(
                child: Center(
                  child: Text(
                    'Form Preview',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              // Spacer to balance the layout
              SizedBox(width: 28),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Program header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: programColor,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.grey[800]!, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Section: Title, Logo, and Subtitle
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    child: _organizationData['logoUrl'] != null
                                        ? Image.network(
                                            _organizationData['logoUrl'],
                                            width: 40,
                                            height: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.business,
                                                color: Colors.grey[800],
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.business,
                                            color: Colors.grey[800],
                                          ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _programData['name'] ??
                                            'Program Preview',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _organizationData['name'] ??
                                            'Organization',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Bottom Section: Due Date
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          color: Colors.grey[800], size: 16),
                                      SizedBox(width: 8),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Due: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            TextSpan(
                                              text: _programData['deadline'] ??
                                                  'No Deadline',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _programData['category'] ?? 'No Category',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Form Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.grey[800]!, width: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _formFields.isEmpty
                                ? [
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Text(
                                          'No form fields defined for this program yet.',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  ]
                                : _renderFormFields(),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: null, // Disabled button
          style: ElevatedButton.styleFrom(
            backgroundColor: darkenColor(programColor),
            disabledBackgroundColor: darkenColor(programColor).withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'Submit Application',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _renderFormFields() {
    List<Widget> fields = [];

    for (int i = 0; i < _formFields.length; i++) {
      final field = _formFields[i];
      final type = field['type'] as String;
      final label = field['label'] as String;

      // Add each form field
      fields.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add the field label
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),

            // Render based on field type
            if (type == 'short_answer')
              TextField(
                controller: _textControllers[label],
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: field['placeholder'] ?? 'Enter your answer',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // Preview mode
              )
            else if (type == 'paragraph')
              TextField(
                controller: _textControllers[label],
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: field['placeholder'] ?? 'Enter your answer',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // Preview mode
              )
            else if (type == 'multiple_choice' && field['options'] != null)
              ...((field['options'] as List).map((option) {
                return RadioListTile<String>(
                  title: Text(option.toString()),
                  value: option.toString(),
                  groupValue: _selectedOptions[label],
                  onChanged: null, // Disabled in preview
                );
              }).toList())
            else if (type == 'checkbox' && field['options'] != null)
              ...((field['options'] as List).map((option) {
                return CheckboxListTile(
                  title: Text(option.toString()),
                  value: _checkboxValues[label]?[option.toString()] ?? false,
                  onChanged: null, // Disabled in preview
                );
              }).toList())
            else if (type == 'date')
              TextField(
                decoration: InputDecoration(
                  hintText: _selectedDates[label] != null
                      ? '${_selectedDates[label]!.toLocal()}'.split(' ')[0]
                      : 'Select a date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
              )
            else if (type == 'attachment')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: null, // Disabled in preview
                    icon: Icon(Icons.attach_file),
                    label: Text('Upload Files'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[800],
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'File uploads are available in the actual application form',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

            // Add spacing between fields
            SizedBox(height: 24),
          ],
        ),
      );
    }

    return fields;
  }
}
