import 'package:flutter/material.dart';
import 'preview_forms_program_page.dart'; // Add this import
import 'package:unloque/models/program_form_field.dart';

class FormEditorTab extends StatefulWidget {
  final List<ProgramFormField> formFields;
  final ValueChanged<List<ProgramFormField>> updateFormFields;
  final bool isLoading;
  final String organizationId; // Add this property
  final String programId; // Add this property

  const FormEditorTab({
    Key? key,
    required this.formFields,
    required this.updateFormFields,
    required this.isLoading,
    required this.organizationId, // Add this parameter
    required this.programId, // Add this parameter
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

  // Add persistent controller map instead of creating temporary controllers in dialog
  final Map<String, TextEditingController> _dialogControllers = {};

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

    // Dispose all persisted dialog controllers
    for (var controller in _dialogControllers.values) {
      controller.dispose();
    }
    _dialogControllers.clear();

    super.dispose();
  }

  void _initNextFormId() {
    int highestId = 0;
    for (var field in widget.formFields) {
      final parsedId = int.tryParse(field.id);
      if (parsedId != null && parsedId > highestId) {
        highestId = parsedId;
      }
    }
    _nextFormId = highestId + 1;
  }

  // Show dialog to select field type before adding
  void _showAddFieldTypeDialog() {
    String selectedType = 'short_answer';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 400,
          constraints: BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Field Type',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: _fieldTypes.map((type) {
                    String displayText = _getFieldTypeDisplay(type);
                    return DropdownMenuItem(
                      value: type,
                      child: Text(displayText),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedType = value!;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _addFormField(selectedType);
                        Navigator.of(context).pop();
                      },
                      child: Text('Add Field'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modified to accept field type parameter
  void _addFormField(String fieldType) {
    final updatedFields = List<ProgramFormField>.from(widget.formFields);
    final type = programFormFieldTypeFromString(fieldType);

    final newField = ProgramFormField(
      id: (_nextFormId++).toString(),
      type: type,
      label: 'New Field',
      required: true,
      options: (type == ProgramFormFieldType.multipleChoice ||
              type == ProgramFormFieldType.checkbox)
          ? const ['Option 1', 'Option 2', 'Option 3']
          : const <String>[],
    );

    updatedFields.add(newField);
    widget.updateFormFields(updatedFields);
  }

  void _removeFormField(int index) {
    final updatedFields = List<ProgramFormField>.from(widget.formFields);
    updatedFields.removeAt(index);
    widget.updateFormFields(updatedFields);
  }

  void _updateFormField(int index, ProgramFormField updatedField) {
    final updatedFields = List<ProgramFormField>.from(widget.formFields);
    updatedFields[index] = updatedField;
    widget.updateFormFields(updatedFields);
  }

  // Helper method to get or create a controller with a unique key
  TextEditingController _getOrCreateController(String key, String initialText) {
    if (!_dialogControllers.containsKey(key)) {
      _dialogControllers[key] = TextEditingController(text: initialText);
    } else if (_dialogControllers[key]!.text != initialText) {
      // Update text if needed but don't create a new controller
      _dialogControllers[key]!.text = initialText;
    }
    return _dialogControllers[key]!;
  }

  // Modified dialog method that uses persistent controllers
  void _showEditFieldDialog(int index) {
    final field = widget.formFields[index];
    final fieldId = field.id.isNotEmpty ? field.id : index.toString();

    // Use persistent controllers instead of local ones
    final labelController =
      _getOrCreateController('label_$fieldId', field.label);

    // Remove placeholderController since it's no longer needed

    String selectedType = programFormFieldTypeToString(field.type);
    bool isRequired = field.required;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 400, // Fixed width for the dialog
            constraints: BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Form Field',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Field type selection
                        Text('Field Type',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedType,
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
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          isExpanded: true, // Make dropdown fit fixed width
                        ),
                        SizedBox(height: 16),

                        // Field label
                        Text('Field Label',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        TextField(
                          controller: labelController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Remove placeholder text field section completely

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
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Just close dialog without disposing controllers
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Update the form field (but preserve options if they exist)
                          var updatedField = widget.formFields[index].copyWith(
                            type: programFormFieldTypeFromString(selectedType),
                            label: labelController.text,
                            required: isRequired,
                          );

                          // Remove placeholder handling for short_answer and paragraph types

                          // If changing to multiple_choice or checkbox and no options exist, add defaults
                          if ((selectedType == 'multiple_choice' ||
                                  selectedType == 'checkbox') &&
                              updatedField.options.isEmpty) {
                            updatedField = updatedField.copyWith(
                              options: const ['Option 1', 'Option 2', 'Option 3'],
                            );
                          }

                          _updateFormField(index, updatedField);
                          Navigator.of(context).pop();
                        },
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add methods to move fields up and down
  void _moveFormFieldUp(int index) {
    if (index <= 0) return; // Can't move up if it's the first item

    final updatedFields = List<ProgramFormField>.from(widget.formFields);
    final temp = updatedFields[index];
    updatedFields[index] = updatedFields[index - 1];
    updatedFields[index - 1] = temp;

    widget.updateFormFields(updatedFields);
  }

  void _moveFormFieldDown(int index) {
    if (index >= widget.formFields.length - 1)
      return; // Can't move down if it's the last item

    final updatedFields = List<ProgramFormField>.from(widget.formFields);
    final temp = updatedFields[index];
    updatedFields[index] = updatedFields[index + 1];
    updatedFields[index + 1] = temp;

    widget.updateFormFields(updatedFields);
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
              // Preview button
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to preview page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PreviewFormsProgramPage(
                          organizationId: widget
                              .organizationId, // Updated to use widget property
                          programId: widget
                              .programId, // Updated to use widget property
                          formFields: widget.formFields,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.visibility),
                  label: Text('Preview Saved Form'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

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
                  onPressed:
                      _showAddFieldTypeDialog, // Changed from _addFormField to _showAddFieldTypeDialog
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
  Widget _buildFormFieldCard(int index, ProgramFormField field) {
    final type = programFormFieldTypeToString(field.type);
    final label = field.label;
    final isRequired = field.required;

    // Determine if this is the first or last item to disable buttons
    final isFirstItem = index == 0;
    final isLastItem = index == widget.formFields.length - 1;

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
          // Card header - modified to show label below type
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with type indicator and action buttons
                Row(
                  children: [
                    // Field type indicator - make slightly smaller
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getFieldTypeColor(type),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _getFieldTypeDisplay(type),
                        style: TextStyle(
                          fontSize: 10, // Reduced font size
                          color: _getFieldTypeTextColor(type),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Required indicator - make more compact
                    if (isRequired)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 4.0), // Reduced padding
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1), // Smaller padding
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius:
                                BorderRadius.circular(3), // Smaller radius
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 9, // Even smaller font
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    Spacer(),

                    // Create a row of action icons with zero spacing
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reordering buttons - even more compact
                        IconButton(
                          onPressed: isFirstItem
                              ? null
                              : () => _moveFormFieldUp(index),
                          icon: Icon(Icons.arrow_upward,
                              size: 16, // Smaller icon
                              color: isFirstItem
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                              minWidth: 24,
                              minHeight: 24), // Smaller constraints
                          tooltip: 'Move Up',
                        ),
                        IconButton(
                          onPressed: isLastItem
                              ? null
                              : () => _moveFormFieldDown(index),
                          icon: Icon(Icons.arrow_downward,
                              size: 16, // Smaller icon
                              color: isLastItem
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                              minWidth: 24,
                              minHeight: 24), // Smaller constraints
                          tooltip: 'Move Down',
                        ),
                        IconButton(
                          onPressed: () => _showEditFieldDialog(index),
                          icon: Icon(Icons.edit,
                              size: 16,
                              color: Colors.grey[600]), // Smaller icon
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                              minWidth: 24,
                              minHeight: 24), // Smaller constraints
                          tooltip: 'Edit Field',
                        ),
                        IconButton(
                          onPressed: () => _removeFormField(index),
                          icon: Icon(Icons.delete,
                              size: 16,
                              color: Colors.grey[600]), // Smaller icon
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                              minWidth: 24,
                              minHeight: 24), // Smaller constraints
                          tooltip: 'Remove Field',
                        ),
                      ],
                    ),
                  ],
                ),

                // Label displayed below type
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // Field content/preview with inline editing for options
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFieldContentTyped(index, field),
          ),
        ],
      ),
    );
  }

  // Typed overload used by _buildFormFieldCard
  Widget _buildFieldContentTyped(int index, ProgramFormField field) {
    final type = programFormFieldTypeToString(field.type);
    final stableFieldId = field.id.isNotEmpty ? field.id : index.toString();

    switch (type) {
      case 'short_answer':
        return TextField(
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        );

      case 'paragraph':
        return TextField(
          readOnly: true,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        );

      case 'multiple_choice':
      case 'checkbox':
        final options = field.options.isEmpty ? const [''] : field.options;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              final controllerKey =
                  'field_${stableFieldId}_option_$optionIndex';

              if (!_optionControllers.containsKey(controllerKey)) {
                _optionControllers[controllerKey] =
                    TextEditingController(text: option);
              } else if (_optionControllers[controllerKey]!.text != option) {
                _optionControllers[controllerKey]!.text = option;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                          hintText: '',
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
            hintText: '',
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
    }

    return Text('');
  }

  // Method to update an option's text
  void _updateOptionText(int fieldIndex, int optionIndex, String newText) {
    final updatedFields = List<ProgramFormField>.from(widget.formFields);
    final field = updatedFields[fieldIndex];

    final options = List<String>.from(field.options);
    if (optionIndex >= options.length) return;

    options[optionIndex] = newText;
    updatedFields[fieldIndex] = field.copyWith(options: options);
    widget.updateFormFields(updatedFields);
  }

  // Method to add a new option
  void _addOption(int fieldIndex) {
    final updatedFields = List<ProgramFormField>.from(widget.formFields);
    final field = updatedFields[fieldIndex];
    final options = List<String>.from(field.options);
    options.add('');
    updatedFields[fieldIndex] = field.copyWith(options: options);
    widget.updateFormFields(updatedFields);
  }

  // Method to remove an option
  void _removeOption(int fieldIndex, int optionIndex) {
    final updatedFields = List<ProgramFormField>.from(widget.formFields);
    final field = updatedFields[fieldIndex];
    final stableFieldId = field.id.isNotEmpty ? field.id : fieldIndex.toString();
    final options = List<String>.from(field.options);
    if (optionIndex >= options.length) return;

    final controllerKey = 'field_${stableFieldId}_option_$optionIndex';
    if (_optionControllers.containsKey(controllerKey)) {
      _optionControllers[controllerKey]?.dispose();
      _optionControllers.remove(controllerKey);
    }

    options.removeAt(optionIndex);
    updatedFields[fieldIndex] = field.copyWith(options: options);
    widget.updateFormFields(updatedFields);
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
      final stableFieldId =
          field.id.isNotEmpty ? field.id : fieldIndex.toString();

      if (field.supportsOptions) {
        for (var optionIndex = 0;
            optionIndex < field.options.length;
            optionIndex++) {
          final controllerKey = 'field_${stableFieldId}_option_$optionIndex';
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

    // Clean up controllers for fields that no longer exist
    final existingFieldIds =
      widget.formFields.map((f) => f.id).toSet();

    final keysToRemoveDialog = _dialogControllers.keys.where((key) {
      // Extract the ID part from the controller key (format: type_id)
      final idPart = key.split('_').sublist(1).join('_');
      return !existingFieldIds.contains(idPart);
    }).toList();

    for (var key in keysToRemoveDialog) {
      _dialogControllers[key]?.dispose();
      _dialogControllers.remove(key);
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
