import 'package:flutter/material.dart';

class FormEditorTab extends StatefulWidget {
  final List<Map<String, dynamic>> formFields;
  final Function(List<Map<String, dynamic>>) updateFormFields;
  final bool isLoading;

  const FormEditorTab({
    Key? key,
    required this.formFields,
    required this.updateFormFields,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<FormEditorTab> createState() => _FormEditorTabState();
}

class _FormEditorTabState extends State<FormEditorTab> {
  int _nextFormId = 1;
  final List<String> _fieldTypes = [
    'short_answer',
    'paragraph',
    'multiple_choice',
    'checkbox',
    'date',
    'attachment'
  ];

  // Add a map to store controllers for each option in multiple choice/checkbox fields
  final Map<String, TextEditingController> _optionControllers = {};

  @override
  void initState() {
    super.initState();
    _initNextFormId();
  }

  @override
  void dispose() {
    // Dispose all option controllers
    for (var controller in _optionControllers.values) {
      controller.dispose();
    }
    _optionControllers.clear();
    super.dispose();
  }

  void _initNextFormId() {
    int highestId = 0;
    for (var field in widget.formFields) {
      if (field['id'] != null &&
          field['id'] is int &&
          field['id'] > highestId) {
        highestId = field['id'];
      }
    }
    _nextFormId = highestId + 1;
  }

  void _addFormField() {
    List<Map<String, dynamic>> updatedFields = List.from(widget.formFields);
    updatedFields.add({
      'id': _nextFormId++,
      'type': 'short_answer',
      'label': 'New Field',
      'placeholder': 'Enter your answer',
      'required': true,
    });
    widget.updateFormFields(updatedFields);
  }

  void _removeFormField(int index) {
    List<Map<String, dynamic>> updatedFields = List.from(widget.formFields);
    updatedFields.removeAt(index);
    widget.updateFormFields(updatedFields);
  }

  void _updateFormField(int index, Map<String, dynamic> newData) {
    List<Map<String, dynamic>> updatedFields = List.from(widget.formFields);
    updatedFields[index] = {
      ...updatedFields[index],
      ...newData,
    };
    widget.updateFormFields(updatedFields);
  }

  void _showEditFieldDialog(int index) {
    final field = widget.formFields[index];
    final TextEditingController labelController =
        TextEditingController(text: field['label']);
    final TextEditingController placeholderController =
        TextEditingController(text: field['placeholder']);
    String selectedType = field['type'];
    bool isRequired = field['required'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Form Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field type selection
                Text('Field Type',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: _fieldTypes.map((type) {
                    String displayText = type;
                    switch (type) {
                      case 'short_answer':
                        displayText = 'Short Answer';
                        break;
                      case 'paragraph':
                        displayText = 'Paragraph';
                        break;
                      case 'multiple_choice':
                        displayText = 'Multiple Choice';
                        break;
                      case 'checkbox':
                        displayText = 'Checkbox';
                        break;
                      case 'date':
                        displayText = 'Date';
                        break;
                      case 'attachment':
                        displayText = 'Attachment';
                        break;
                    }

                    return DropdownMenuItem(
                      value: type,
                      child: Text(displayText),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                SizedBox(height: 16),

                // Field label
                Text('Field Label',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter field label',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                SizedBox(height: 16),

                // Field placeholder
                if (selectedType == 'short_answer' ||
                    selectedType == 'paragraph') ...[
                  Text('Placeholder Text',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: placeholderController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter placeholder text',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Required checkbox
                Row(
                  children: [
                    Checkbox(
                      value: isRequired,
                      onChanged: (value) {
                        setDialogState(() {
                          isRequired = value!;
                        });
                      },
                    ),
                    Text('Required field'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Dispose all controllers before closing
                labelController.dispose();
                placeholderController.dispose();
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the form field (but preserve options if they exist)
                Map<String, dynamic> updatedField = {
                  ...widget.formFields[index],
                  'type': selectedType,
                  'label': labelController.text,
                  'required': isRequired,
                };

                if (selectedType == 'short_answer' ||
                    selectedType == 'paragraph') {
                  updatedField['placeholder'] = placeholderController.text;
                }

                // If changing to multiple_choice or checkbox and no options exist, add defaults
                if ((selectedType == 'multiple_choice' ||
                        selectedType == 'checkbox') &&
                    (!updatedField.containsKey('options') ||
                        (updatedField['options'] as List?)?.isEmpty == true)) {
                  updatedField['options'] = [
                    'Option 1',
                    'Option 2',
                    'Option 3'
                  ];
                }

                _updateFormField(index, updatedField);

                // Dispose controllers
                labelController.dispose();
                placeholderController.dispose();

                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to add an option with proper controller management
  void _addOptionWithController(
      List<TextEditingController> controllers, StateSetter setState) {
    setState(() {
      controllers.add(TextEditingController(text: 'New Option'));
    });
  }

  // Helper method to remove an option with proper controller disposal
  void _removeOptionWithController(List<TextEditingController> controllers,
      int index, StateSetter setState) {
    setState(() {
      // Dispose the controller before removing it
      controllers[index].dispose();
      controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form instructions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form Builder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create and customize application form fields. These fields will be shown to applicants when they apply for this program.',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Form fields
              ...widget.formFields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                return _buildFormFieldCard(index, field);
              }),

              // Add field button
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addFormField,
                  icon: Icon(Icons.add),
                  label: Text('Add Form Field'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),

        // Loading indicator
        if (widget.isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // Build a form field card with inline option editing
  Widget _buildFormFieldCard(int index, Map<String, dynamic> field) {
    final type = field['type'] as String;
    final label = field['label'] as String;
    final isRequired = field['required'] ?? true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                // Field type indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getFieldTypeColor(type),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getFieldTypeDisplay(type),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getFieldTypeTextColor(type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),

                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                SizedBox(width: 8),

                // Required indicator
                if (isRequired)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                Spacer(),

                // Edit and delete buttons
                IconButton(
                  onPressed: () => _showEditFieldDialog(index),
                  icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: 'Edit Field',
                ),
                SizedBox(width: 12),
                IconButton(
                  onPressed: () => _removeFormField(index),
                  icon: Icon(Icons.delete, size: 20, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: 'Remove Field',
                ),
              ],
            ),
          ),

          // Field content/preview with inline editing for options
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFieldContent(index, field),
          ),
        ],
      ),
    );
  }

  // Helper method to build field content based on type
  Widget _buildFieldContent(int index, Map<String, dynamic> field) {
    final type = field['type'] as String;

    switch (type) {
      case 'short_answer':
        return TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: field['placeholder'] ?? 'Short answer text',
            border: OutlineInputBorder(),
          ),
        );

      case 'paragraph':
        return TextField(
          readOnly: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: field['placeholder'] ?? 'Long answer text',
            border: OutlineInputBorder(),
          ),
        );

      case 'multiple_choice':
      case 'checkbox':
        // Inline option editing for multiple choice and checkbox
        List<dynamic> options =
            field['options'] as List<dynamic>? ?? ['Option 1'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value.toString();

              // Create a unique key for this option's controller
              final controllerKey = 'field_${field['id']}_option_$optionIndex';

              // Create or reuse controller
              if (!_optionControllers.containsKey(controllerKey)) {
                _optionControllers[controllerKey] =
                    TextEditingController(text: option);
              } else if (_optionControllers[controllerKey]!.text != option) {
                // Update controller text if different
                _optionControllers[controllerKey]!.text = option;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Show correct icon based on field type
                    Icon(
                      type == 'multiple_choice'
                          ? Icons.radio_button_unchecked
                          : Icons.check_box_outline_blank,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[controllerKey],
                        decoration: InputDecoration(
                          hintText: 'Enter option text',
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.only(bottom: 8),
                        ),
                        onChanged: (value) {
                          _updateOptionText(index, optionIndex, value);
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: options.length > 1
                          ? () => _removeOption(index, optionIndex)
                          : null,
                    ),
                  ],
                ),
              );
            }).toList(),

            // Add option button
            TextButton.icon(
              onPressed: () => _addOption(index),
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Option'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        );

      case 'date':
        return TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select date',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
          ),
        );

      case 'attachment':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File upload field',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_file, size: 20, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Upload Files',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return Text('Unknown field type');
    }
  }

  // Method to update an option's text
  void _updateOptionText(int fieldIndex, int optionIndex, String newText) {
    List<Map<String, dynamic>> updatedFields = List.from(widget.formFields);

    if (updatedFields[fieldIndex]['options'] == null) {
      updatedFields[fieldIndex]['options'] = [];
    }

    List<dynamic> options = List.from(updatedFields[fieldIndex]['options']);

    if (optionIndex < options.length) {
      options[optionIndex] = newText;
      updatedFields[fieldIndex]['options'] = options;
      widget.updateFormFields(updatedFields);
    }
  }

  // Method to add a new option
  void _addOption(int fieldIndex) {
    List<Map<String, dynamic>> updatedFields = List.from(widget.formFields);

    if (updatedFields[fieldIndex]['options'] == null) {
      updatedFields[fieldIndex]['options'] = [];
    }

    List<dynamic> options = List.from(updatedFields[fieldIndex]['options']);
    options.add('New Option');
    updatedFields[fieldIndex]['options'] = options;

    widget.updateFormFields(updatedFields);
  }

  // Method to remove an option
  void _removeOption(int fieldIndex, int optionIndex) {
    List<Map<String, dynamic>> updatedFields = List.from(widget.formFields);
    List<dynamic> options = List.from(updatedFields[fieldIndex]['options']);

    if (optionIndex < options.length) {
      // Find and dispose the controller for this option
      final controllerKey =
          'field_${updatedFields[fieldIndex]['id']}_option_$optionIndex';
      if (_optionControllers.containsKey(controllerKey)) {
        _optionControllers[controllerKey]?.dispose();
        _optionControllers.remove(controllerKey);
      }

      options.removeAt(optionIndex);
      updatedFields[fieldIndex]['options'] = options;
      widget.updateFormFields(updatedFields);
    }
  }

  // Clean up controllers for removed field IDs in didUpdateWidget
  @override
  void didUpdateWidget(FormEditorTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clean up controllers for items that no longer exist
    final Set<String> currentKeys = {};

    // Collect all current keys for options
    for (var fieldIndex = 0;
        fieldIndex < widget.formFields.length;
        fieldIndex++) {
      final field = widget.formFields[fieldIndex];
      if ((field['type'] == 'multiple_choice' || field['type'] == 'checkbox') &&
          field['options'] != null) {
        final options = field['options'] as List;
        for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
          final controllerKey = 'field_${field['id']}_option_$optionIndex';
          currentKeys.add(controllerKey);
        }
      }
    }

    // Remove and dispose controllers that are no longer needed
    final keysToRemove = _optionControllers.keys
        .where((key) => !currentKeys.contains(key))
        .toList();

    for (var key in keysToRemove) {
      _optionControllers[key]?.dispose();
      _optionControllers.remove(key);
    }
  }

  // Helper method to get field type display text
  String _getFieldTypeDisplay(String type) {
    switch (type) {
      case 'short_answer':
        return 'Short Answer';
      case 'paragraph':
        return 'Paragraph';
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'checkbox':
        return 'Checkbox';
      case 'date':
        return 'Date';
      case 'attachment':
        return 'Attachment';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get field type color
  Color _getFieldTypeColor(String type) {
    switch (type) {
      case 'short_answer':
      case 'paragraph':
        return Colors.blue[100]!;
      case 'multiple_choice':
      case 'checkbox':
        return Colors.green[100]!;
      case 'date':
        return Colors.orange[100]!;
      case 'attachment':
        return Colors.purple[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  // Helper method to get field type text color
  Color _getFieldTypeTextColor(String type) {
    switch (type) {
      case 'short_answer':
      case 'paragraph':
        return Colors.blue[800]!;
      case 'multiple_choice':
      case 'checkbox':
        return Colors.green[800]!;
      case 'date':
        return Colors.orange[800]!;
      case 'attachment':
        return Colors.purple[800]!;
      default:
        return Colors.grey[800]!;
    }
  }
}
