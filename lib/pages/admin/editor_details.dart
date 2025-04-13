import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DetailsEditorTab extends StatefulWidget {
  final String organizationId;
  final String programId;
  final List<Map<String, dynamic>> detailSections;
  final Function(List<Map<String, dynamic>>) updateDetailSections;
  final bool isLoading;

  const DetailsEditorTab({
    Key? key,
    required this.organizationId,
    required this.programId,
    required this.detailSections,
    required this.updateDetailSections,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<DetailsEditorTab> createState() => _DetailsEditorTabState();
}

class _DetailsEditorTabState extends State<DetailsEditorTab> {
  Map<String, bool> _uploadingFiles = {};
  int _nextDetailId = 0;
  final List<String> _detailTypes = ['paragraph', 'list', 'attachment'];

  // Add a map to store controllers for each list item
  final Map<String, TextEditingController> _listItemControllers = {};

  // Add a map to store controllers for paragraphs and list items to avoid recreation
  final Map<String, TextEditingController> _contentControllers = {};

  @override
  void initState() {
    super.initState();
    _initNextDetailId();
    _initControllers();
  }

  // Initialize controllers for existing content
  void _initControllers() {
    for (var section in widget.detailSections) {
      if (section['type'] == 'paragraph' && section['content'] != null) {
        final String key = 'paragraph_${section['id']}';
        _contentControllers[key] =
            TextEditingController(text: section['content']);
      }

      if (section['type'] == 'list' && section['items'] != null) {
        final items = section['items'] as List<dynamic>;
        for (int i = 0; i < items.length; i++) {
          final String key = 'list_${section['id']}_$i';
          _contentControllers[key] =
              TextEditingController(text: items[i].toString());
        }
      }
    }
  }

  @override
  void dispose() {
    // Dispose all list item controllers
    for (var controller in _listItemControllers.values) {
      controller.dispose();
    }
    _listItemControllers.clear();

    // Dispose all controllers
    for (var controller in _contentControllers.values) {
      controller.dispose();
    }
    _contentControllers.clear();

    for (var controller in _uploadingFiles.keys) {
      _uploadingFiles[controller] = false;
    }

    super.dispose();
  }

  void _initNextDetailId() {
    int highestId = 0;
    for (var section in widget.detailSections) {
      if (section['id'] != null &&
          section['id'] is int &&
          section['id'] > highestId) {
        highestId = section['id'];
      }
    }
    _nextDetailId = highestId + 1;
  }

  void _addDetailSection(String type) {
    List<Map<String, dynamic>> updatedSections =
        List.from(widget.detailSections);

    Map<String, dynamic> newSection = {
      'id': _nextDetailId++,
      'type': type,
      'label': 'New Section',
    };

    // Add type-specific fields
    if (type == 'paragraph') {
      newSection['content'] = '';
    } else if (type == 'list') {
      newSection['items'] = ['Enter an item'];
    } else if (type == 'attachment') {
      newSection['files'] = [];
    }

    updatedSections.add(newSection);
    widget.updateDetailSections(updatedSections);
  }

  void _removeDetailSection(int index) {
    List<Map<String, dynamic>> updatedSections =
        List.from(widget.detailSections);
    updatedSections.removeAt(index);
    widget.updateDetailSections(updatedSections);
  }

  void _updateDetailSection(int index, Map<String, dynamic> newData) {
    List<Map<String, dynamic>> updatedSections =
        List.from(widget.detailSections);
    updatedSections[index] = {
      ...updatedSections[index],
      ...newData,
    };
    widget.updateDetailSections(updatedSections);
  }

  void _addListItem(int sectionIndex) {
    List<Map<String, dynamic>> updatedSections =
        List.from(widget.detailSections);
    List<String> items =
        List<String>.from(updatedSections[sectionIndex]['items'] as List);
    items.add('Enter an item');
    updatedSections[sectionIndex]['items'] = items;
    widget.updateDetailSections(updatedSections);
  }

  void _removeListItem(int sectionIndex, int itemIndex) {
    List<Map<String, dynamic>> updatedSections =
        List.from(widget.detailSections);
    List<String> items =
        List<String>.from(updatedSections[sectionIndex]['items'] as List);

    // Remove the controller for the item being deleted
    final key = 'list_${updatedSections[sectionIndex]['id']}_$itemIndex';
    if (_contentControllers.containsKey(key)) {
      _contentControllers[key]?.dispose();
      _contentControllers.remove(key);
    }

    // Remove the item
    items.removeAt(itemIndex);
    updatedSections[sectionIndex]['items'] = items;

    // Update controllers for all subsequent items (they shift down)
    for (int i = itemIndex; i < items.length; i++) {
      final oldKey = 'list_${updatedSections[sectionIndex]['id']}_${i + 1}';
      final newKey = 'list_${updatedSections[sectionIndex]['id']}_$i';

      if (_contentControllers.containsKey(oldKey)) {
        _contentControllers[newKey] = _contentControllers[oldKey]!;
        _contentControllers.remove(oldKey);
      }
    }

    widget.updateDetailSections(updatedSections);
  }

  void _updateListItem(int sectionIndex, int itemIndex, String newText) {
    List<Map<String, dynamic>> updatedSections =
        List.from(widget.detailSections);
    List<String> items =
        List<String>.from(updatedSections[sectionIndex]['items'] as List);
    items[itemIndex] = newText;
    updatedSections[sectionIndex]['items'] = items;
    widget.updateDetailSections(updatedSections);
  }

  // Method to upload file to Firebase Storage
  Future<String?> _uploadFile(File file, String sectionId) async {
    try {
      final fileName = path.basename(file.path);
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Reference to the storage location
      final storageRef = FirebaseStorage.instance.ref().child(
          'organizations/${widget.organizationId}/programs/${widget.programId}/details/$sectionId/$uniqueFileName');

      // Start upload
      final uploadTask = storageRef.putFile(file);

      // Set metadata for the file
      final metadata = SettableMetadata(contentType: _getContentType(fileName));

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Helper method to determine content type
  String _getContentType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // Method to download and open a file
  Future<void> _downloadAndOpenFile(String downloadUrl, String fileName) async {
    setState(() {
      _uploadingFiles[fileName] = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/$fileName';
      final file = File(localPath);

      // Download file if it doesn't exist locally
      if (!await file.exists()) {
        final response = await http.get(Uri.parse(downloadUrl));
        await file.writeAsBytes(response.bodyBytes);
      }

      // Open the file
      await OpenFilex.open(localPath);
    } catch (e) {
      print('Error downloading/opening file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    } finally {
      setState(() {
        _uploadingFiles[fileName] = false;
      });
    }
  }

  // Method to delete a file from Firebase Storage
  Future<void> _deleteFile(String downloadUrl) async {
    try {
      // Get reference from URL and delete
      final ref = FirebaseStorage.instance.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting file from storage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  void _showEditDetailDialog(int index) {
    final section = widget.detailSections[index];
    final labelController = TextEditingController(text: section['label']);
    String selectedType = section['type'];

    // For paragraph type
    final contentController = TextEditingController(
        text: section['type'] == 'paragraph' ? section['content'] : '');

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
                  Text('Edit Detail Section',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section type selection (disabled as changing type would require restructuring data)
                        Text('Section Type',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          items: _detailTypes.map((type) {
                            String displayText = type;
                            switch (type) {
                              case 'paragraph':
                                displayText = 'Paragraph';
                                break;
                              case 'list':
                                displayText = 'List';
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
                          onChanged: null, // Disabled to prevent type changes
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          isExpanded: true, // Make dropdown fit fixed width
                        ),
                        SizedBox(height: 16),

                        // Section label
                        Text('Section Label',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        TextField(
                          controller: labelController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter section label',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Content field for paragraph type
                        if (selectedType == 'paragraph') ...[
                          Text('Content',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          TextField(
                            controller: contentController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter paragraph content',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Map<String, dynamic> updatedData = {
                            'label': labelController.text,
                          };

                          if (selectedType == 'paragraph') {
                            updatedData['content'] = contentController.text;
                          }

                          _updateDetailSection(index, updatedData);
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

  // Apply similar fixes to the _showAddDetailDialog method
  void _showAddDetailDialog() {
    String selectedType = 'paragraph';

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
                children: [
                  Text('Add Detail Section',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text('Select Section Type'),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: _detailTypes.map((type) {
                      String displayText = type;
                      switch (type) {
                        case 'paragraph':
                          displayText = 'Paragraph';
                          break;
                        case 'list':
                          displayText = 'List';
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
                    ),
                    isExpanded: true, // Make dropdown fit fixed width
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _addDetailSection(selectedType);
                          Navigator.pop(context);
                        },
                        child: Text('Add'),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
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
                      'Details Builder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create and customize program detail sections. These sections will be shown to applicants when they view this program.',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Detail Sections List
              ...widget.detailSections.asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                return _buildDetailSectionCard(index, section);
              }),

              // Add section button
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _showAddDetailDialog,
                  icon: Icon(Icons.add),
                  label: Text('Add Detail Section'),
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

  // Build a detail section card
  Widget _buildDetailSectionCard(int index, Map<String, dynamic> section) {
    final type = section['type'] as String;
    final label = section['label'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: Column(
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
                      // Section type indicator
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSectionTypeColor(type),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getSectionTypeDisplay(type),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getSectionTypeTextColor(type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Spacer(),

                      // Edit and delete buttons
                      IconButton(
                        onPressed: () => _showEditDetailDialog(index),
                        icon:
                            Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Edit Section',
                      ),
                      SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _removeDetailSection(index),
                        icon: Icon(Icons.delete,
                            size: 20, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Remove Section',
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

            // Section content based on type
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSectionContent(index, section),
            ),
          ],
        ),
      ),
    );
  }

  // Build content for a section based on its type
  Widget _buildSectionContent(int index, Map<String, dynamic> section) {
    switch (section['type']) {
      case 'paragraph':
        return _buildParagraphContent(index, section);
      case 'list':
        return _buildListContent(index, section);
      case 'attachment':
        return _buildAttachmentContent(index, section);
      default:
        return Text('Unknown section type');
    }
  }

  // Build paragraph type content
  Widget _buildParagraphContent(int index, Map<String, dynamic> section) {
    final String key = 'paragraph_${section['id']}';

    // Create controller if it doesn't exist
    if (!_contentControllers.containsKey(key)) {
      _contentControllers[key] =
          TextEditingController(text: section['content'] ?? '');
    }

    return TextField(
      maxLines: 6,
      decoration: InputDecoration(
        hintText: 'Enter text content here...',
        border: OutlineInputBorder(),
      ),
      controller: _contentControllers[key],
      onChanged: (value) {
        _updateDetailSection(index, {'content': value});
      },
    );
  }

  // Build list type content
  Widget _buildListContent(int index, Map<String, dynamic> section) {
    // Fix the type casting issue by properly converting dynamic list to string list
    final rawItems = section['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((item) => item.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.asMap().entries.map((entry) {
          final itemIndex = entry.key;
          final item = entry.value;

          // Create a unique key for this list item
          final String controllerKey =
              'section_${section['id']}_item_$itemIndex';

          // Create or reuse controller for this item
          if (!_listItemControllers.containsKey(controllerKey)) {
            _listItemControllers[controllerKey] =
                TextEditingController(text: item);
          } else if (_listItemControllers[controllerKey]!.text != item) {
            // Update controller text if it's different (without triggering rebuild)
            _listItemControllers[controllerKey]!.text = item;
          }

          // Create a unique key for this controller
          final String key = 'list_${section['id']}_$itemIndex';

          // Create controller if it doesn't exist
          if (!_contentControllers.containsKey(key)) {
            _contentControllers[key] = TextEditingController(text: item);
          } else if (_contentControllers[key]!.text != item) {
            // Update controller text if different
            _contentControllers[key]!.text = item;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 12, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _contentControllers[key],
                    decoration: InputDecoration(
                      hintText: 'Enter list item',
                      border: UnderlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.only(bottom: 8),
                    ),
                    onChanged: (value) =>
                        _updateListItem(index, itemIndex, value),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: items.length > 1
                      ? () => _removeListItem(index, itemIndex)
                      : null,
                ),
              ],
            ),
          );
        }).toList(),

        // Add item button
        SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            _addListItem(index);
            // Make sure to create a controller for the new item
            final newIndex = (section['items'] as List).length - 1;
            final key = 'list_${section['id']}_$newIndex';
            _contentControllers[key] =
                TextEditingController(text: 'Enter an item');
          },
          icon: Icon(Icons.add, size: 16),
          label: Text('Add Item'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  // Build attachment type content
  Widget _buildAttachmentContent(int index, Map<String, dynamic> section) {
    final files = section['files'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments will be available to program applicants.',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            FilePickerResult? result =
                await FilePicker.platform.pickFiles(allowMultiple: true);

            if (result != null) {
              for (var pickedFile in result.files) {
                if (pickedFile.path == null) continue;

                final file = File(pickedFile.path!);
                final fileName = pickedFile.name;

                setState(() {
                  _uploadingFiles[fileName] = true;
                });

                try {
                  // Upload file to Firebase Storage
                  final downloadUrl =
                      await _uploadFile(file, 'section_${section['id']}');

                  if (downloadUrl != null) {
                    List<Map<String, dynamic>> updatedSections =
                        List.from(widget.detailSections);

                    if (updatedSections[index]['files'] == null) {
                      updatedSections[index]['files'] = [];
                    }

                    (updatedSections[index]['files'] as List).add({
                      'name': fileName,
                      'downloadUrl': downloadUrl,
                      'uploadedAt': DateTime.now().toIso8601String(),
                    });

                    widget.updateDetailSections(updatedSections);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File uploaded successfully')),
                    );
                  }
                } catch (e) {
                  print('Error handling file upload: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error uploading file: $e')),
                  );
                } finally {
                  setState(() {
                    _uploadingFiles[fileName] = false;
                  });
                }
              }
            }
          },
          icon: Icon(Icons.attach_file),
          label: Text('Upload Files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.grey[800],
          ),
        ),

        // Display list of uploaded files
        if (files.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(
            'Uploaded Files',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          ...files.asMap().entries.map((entry) {
            final fileIndex = entry.key;
            final fileData = Map<String, dynamic>.from(entry.value as Map);
            final fileName = fileData['name'] ?? 'Unknown file';
            final downloadUrl = fileData['downloadUrl'];
            final isUploading = _uploadingFiles[fileName] ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  isUploading
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.insert_drive_file,
                          size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (downloadUrl != null) {
                          _downloadAndOpenFile(downloadUrl, fileName);
                        }
                      },
                      child: Text(
                        fileName,
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () async {
                      // Delete file from storage and remove from list
                      if (downloadUrl != null) {
                        await _deleteFile(downloadUrl);

                        List<Map<String, dynamic>> updatedSections =
                            List.from(widget.detailSections);
                        (updatedSections[index]['files'] as List)
                            .removeAt(fileIndex);
                        widget.updateDetailSections(updatedSections);
                      }
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  // Helper methods for section types
  Color _getSectionTypeColor(String type) {
    switch (type) {
      case 'paragraph':
        return Colors.blue[100]!;
      case 'list':
        return Colors.green[100]!;
      case 'attachment':
        return Colors.amber[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getSectionTypeTextColor(String type) {
    switch (type) {
      case 'paragraph':
        return Colors.blue[800]!;
      case 'list':
        return Colors.green[800]!;
      case 'attachment':
        return Colors.amber[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  String _getSectionTypeDisplay(String type) {
    switch (type) {
      case 'paragraph':
        return 'Paragraph';
      case 'list':
        return 'List';
      case 'attachment':
        return 'Attachment';
      default:
        return 'Unknown';
    }
  }

  // Update this method to clean up unused controllers
  @override
  void didUpdateWidget(DetailsEditorTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clean up controllers for items that no longer exist
    final Set<String> currentKeys = {};

    // Collect all current keys
    for (var sectionIndex = 0;
        sectionIndex < widget.detailSections.length;
        sectionIndex++) {
      final section = widget.detailSections[sectionIndex];
      if (section['type'] == 'list' && section['items'] != null) {
        final items = section['items'] as List;
        for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
          final controllerKey = 'section_${section['id']}_item_$itemIndex';
          currentKeys.add(controllerKey);
        }
      }
    }

    // Remove and dispose controllers that are no longer needed
    final keysToRemove = _listItemControllers.keys
        .where((key) => !currentKeys.contains(key))
        .toList();
    for (var key in keysToRemove) {
      _listItemControllers[key]?.dispose();
      _listItemControllers.remove(key);
    }

    // Update controllers if needed
    for (var section in widget.detailSections) {
      if (section['type'] == 'paragraph') {
        final String key = 'paragraph_${section['id']}';
        if (!_contentControllers.containsKey(key)) {
          _contentControllers[key] =
              TextEditingController(text: section['content'] ?? '');
        }
      }

      if (section['type'] == 'list' && section['items'] != null) {
        final items = section['items'] as List<dynamic>;
        for (int i = 0; i < items.length; i++) {
          final String key = 'list_${section['id']}_$i';
          if (!_contentControllers.containsKey(key)) {
            _contentControllers[key] =
                TextEditingController(text: items[i].toString());
          } else {
            // Update controller if text has changed
            final controller = _contentControllers[key]!;
            if (controller.text != items[i].toString()) {
              controller.text = items[i].toString();
            }
          }
        }
      }
    }

    // Clean up unused controllers
    _cleanupUnusedControllers();
  }

  // Clean up controllers that are no longer needed
  void _cleanupUnusedControllers() {
    final Set<String> neededKeys = {};

    // Collect keys for all current content
    for (var section in widget.detailSections) {
      if (section['type'] == 'paragraph') {
        neededKeys.add('paragraph_${section['id']}');
      }

      if (section['type'] == 'list' && section['items'] != null) {
        final items = section['items'] as List<dynamic>;
        for (int i = 0; i < items.length; i++) {
          neededKeys.add('list_${section['id']}_$i');
        }
      }
    }

    // Remove unnecessary controllers
    final keysToRemove = _contentControllers.keys
        .where((key) => !neededKeys.contains(key))
        .toList();
    for (final key in keysToRemove) {
      _contentControllers[key]?.dispose();
      _contentControllers.remove(key);
    }
  }
}
