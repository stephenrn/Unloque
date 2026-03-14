import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import tab widgets
import 'editor_basic.dart';
import 'editor_details.dart';
import 'editor_form.dart';

class ProgramDetailsFormPage extends StatefulWidget {
  final Map<String, dynamic> program;
  final String organizationId;
  final String organizationName;
  final String? organizationLogoUrl;

  const ProgramDetailsFormPage({
    Key? key,
    required this.program,
    required this.organizationId,
    required this.organizationName,
    this.organizationLogoUrl,
  }) : super(key: key);

  @override
  State<ProgramDetailsFormPage> createState() => _ProgramDetailsFormPageState();
}

class _ProgramDetailsFormPageState extends State<ProgramDetailsFormPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _loadingMessage = '';

  // Program data state
  late String _programName;
  late String? _selectedCategory;
  late String _deadline;
  late Color _selectedColor;
  DateTime? _selectedDeadline;

  // Add program status state
  String _programStatus = "Closed";

  // Detail sections and form fields
  List<Map<String, dynamic>> _detailSections = [];
  List<Map<String, dynamic>> _formFields = [];

  // Change to a GlobalKey with the correct type
  final GlobalKey<DetailsEditorTabState> _detailsTabKey =
      GlobalKey<DetailsEditorTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize from program data
    _programName = widget.program['name'] ?? '';
    _selectedCategory = widget.program['category'] ?? 'Educational';
    _deadline = widget.program['deadline'] ?? '';

    // Set color from program data
    if (widget.program['color'] != null) {
      _selectedColor = Color(widget.program['color']);
    } else {
      _selectedColor = Colors.blue[100]!;
    }

    // Set program status from program data or default to "Closed"
    _programStatus = widget.program['programStatus'] ?? "Closed";

    // Load form fields and detail sections data
    _loadFormFields();
    _loadDetailSections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load detail sections from Firestore
  Future<void> _loadDetailSections() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Loading program details...';
    });

    try {
      final programDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('programs')
          .doc(widget.program['id'])
          .get();

      if (programDoc.exists && programDoc.data()?['detailSections'] != null) {
        final detailsData =
            programDoc.data()!['detailSections'] as List<dynamic>;

        setState(() {
          _detailSections = detailsData
              .map((section) => Map<String, dynamic>.from(section))
              .toList();
        });
      } else {
        // Initialize with empty sections instead of defaults
        setState(() {
          _detailSections = [];
        });
      }
    } catch (e) {
      print('Error loading detail sections: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading program details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load form fields from Firestore
  Future<void> _loadFormFields() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Loading program data...';
    });

    try {
      final programDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('programs')
          .doc(widget.program['id'])
          .get();

      if (programDoc.exists && programDoc.data()?['formFields'] != null) {
        final formFieldsData =
            programDoc.data()!['formFields'] as List<dynamic>;

        setState(() {
          _formFields = formFieldsData
              .map((field) => Map<String, dynamic>.from(field))
              .toList();
        });
      } else {
        // Initialize with empty form fields instead of defaults
        setState(() {
          _formFields = [];
        });
      }
    } catch (e) {
      print('Error loading form fields: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading program data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update methods for each property
  void _updateProgramName(String name) {
    setState(() {
      _programName = name;
    });
  }

  void _updateCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _updateDeadline(String deadline) {
    setState(() {
      _deadline = deadline;
    });
  }

  void _updateColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _updateDetailSections(List<Map<String, dynamic>> sections) {
    setState(() {
      _detailSections = sections;
    });
  }

  void _updateFormFields(List<Map<String, dynamic>> fields) {
    setState(() {
      _formFields = fields;
    });
  }

  // Add method to update program status
  void _updateProgramStatus(String status) {
    setState(() {
      _programStatus = status;
    });
  }

  // Show date picker for deadline
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDeadline) {
      setState(() {
        _selectedDeadline = pickedDate;
        _deadline = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }

  // Show color picker dialog
  void _showColorPickerDialog() {
    // List of predefined colors for selection - using lighter variants
    final colors = [
      Colors.blue[100]!,
      Colors.red[100]!,
      Colors.green[100]!,
      Colors.orange[100]!,
      Colors.purple[100]!,
      Colors.teal[100]!,
      Colors.pink[100]!,
      Colors.amber[100]!,
      Colors.indigo[100]!,
      Colors.cyan[100]!,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Color'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () {
                  setDialogState(() {
                    _selectedColor = color;
                  });
                  setState(() {
                    _selectedColor = color;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Save program details and form fields
  Future<void> _saveProgram() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Saving program data...';
    });

    // Store current data before any modifications
    final List<Map<String, dynamic>> originalDetailSections =
        List<Map<String, dynamic>>.from(_detailSections);
    final List<Map<String, dynamic>> originalFormFields =
        List<Map<String, dynamic>>.from(_formFields);

    try {
      // First, handle any pending file uploads in the details tab
      final detailsTabState = _detailsTabKey.currentState;

      if (detailsTabState != null) {
        setState(() {
          _loadingMessage = 'Uploading files...';
        });

        try {
          // Call the method on the state directly
          final updatedDetailSections =
              await detailsTabState.saveDetailSections();

          // Only update the detail sections if we successfully got data back
          if (updatedDetailSections.isNotEmpty) {
            _detailSections =
                List<Map<String, dynamic>>.from(updatedDetailSections);
          }
        } catch (e) {
          print('Error uploading files: $e');
          // Show error message to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading files: $e')),
          );
          // Continue with save process even if file upload fails
        }
      }

      // Now create the program data with the updated sections
      setState(() {
        _loadingMessage = 'Saving program data to database...';
      });

      final programData = {
        'name': _programName,
        'category': _selectedCategory,
        'deadline': _deadline,
        'color': _selectedColor.value,
        'detailSections': _detailSections,
        'formFields': _formFields,
        'programStatus': _programStatus, // Add program status
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('programs')
          .doc(widget.program['id'])
          .update(programData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program saved successfully!')),
      );
    } catch (e) {
      // Restore original data if save fails
      _detailSections = originalDetailSections;
      _formFields = originalFormFields;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving program: $e')),
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
        backgroundColor: Colors.grey[100],
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 60,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                    _isLoading ? _loadingMessage : 'Program Editor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),

              // Save button
              _isLoading
                  ? Container(
                      width: 28,
                      height: 28,
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: _saveProgram,
                      icon: Icon(Icons.save, color: Colors.grey[800], size: 24),
                      tooltip: 'Save Program',
                    ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.grey[800],
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Basic'),
            Tab(text: 'Details'),
            Tab(text: 'Form'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // BASIC TAB
          BasicEditorTab(
            programName: _programName,
            selectedCategory: _selectedCategory,
            deadline: _deadline,
            selectedColor: _selectedColor,
            organizationName: widget.organizationName,
            organizationLogoUrl: widget.organizationLogoUrl,
            programStatus: _programStatus, // Pass program status
            updateName: _updateProgramName,
            updateCategory: _updateCategory,
            updateDeadline: _updateDeadline,
            updateColor: _updateColor,
            showColorPickerDialog: _showColorPickerDialog,
            selectDate: _selectDate,
            updateProgramStatus: _updateProgramStatus, // Pass update function
          ),

          // DETAILS TAB - Important: Don't change the key here
          DetailsEditorTab(
            key: _detailsTabKey,
            organizationId: widget.organizationId,
            programId: widget.program['id'],
            detailSections: _detailSections,
            updateDetailSections: _updateDetailSections,
            isLoading: _isLoading,
          ),

          // FORM TAB
          FormEditorTab(
            formFields: _formFields,
            updateFormFields: _updateFormFields,
            isLoading: _isLoading,
            organizationId: widget.organizationId, // Add this parameter
            programId: widget.program['id'], // Add this parameter
          ),
        ],
      ),
    );
  }
}
