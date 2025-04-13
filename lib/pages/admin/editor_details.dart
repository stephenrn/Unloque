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

  // Remove the const keyword from the constructor
  DetailsEditorTab({
    Key? key,
    required this.organizationId,
    required this.programId,
    required this.detailSections,
    required this.updateDetailSections,
    required this.isLoading,
  }) : super(key: key);

  // Remove stateKey field, as it causes issues with state management

  @override
  State<DetailsEditorTab> createState() => _DetailsEditorTabState();

  // Method that can be called by parent to save details and upload files
  Future<List<Map<String, dynamic>>> saveDetailSections() async {
    // Since we don't have direct access to the state through a key anymore,
    // we need to create a new instance of state functions

    // Create an instance of _DetailsEditorTabStateFunctionality with the current properties
    final stateHelper = _DetailsEditorTabStateFunctionality(
      organizationId: organizationId,
      programId: programId,
      detailSections: detailSections,
    );

    // Process the uploads using the helper instance
    await stateHelper.uploadPendingFiles();

    // Return the updated sections (with file URLs)
    return detailSections;
  }
}

// Helper class to encapsulate state functionality for file uploads
class _DetailsEditorTabStateFunctionality {
  final String organizationId;
  final String programId;
  final List<Map<String, dynamic>> detailSections;

  _DetailsEditorTabStateFunctionality({
    required this.organizationId,
    required this.programId,
    required this.detailSections,
  });

  Future<void> uploadPendingFiles() async {
    // First, find any files that need to be uploaded
    final filesToUpload = <Map<String, dynamic>>[];

    for (var section in detailSections) {
      if (section['type'] == 'attachment' && section['files'] != null) {
        final files = section['files'] as List;
        for (var fileData in files) {
          if (fileData is Map<String, dynamic> &&
              fileData['isPending'] == true &&
              fileData['path'] != null) {
            // Add section ID to the file data for storage path
            final fileWithSectionId = Map<String, dynamic>.from(fileData);
            fileWithSectionId['sectionId'] = section['id'].toString();
            filesToUpload.add(fileWithSectionId);
          }
        }
      }
    }

    // If no files need uploading, return early
    if (filesToUpload.isEmpty) {
      return;
    }

    // Upload each file
    for (var fileData in filesToUpload) {
      try {
        final filePath = fileData['path'];
        final fileName = fileData['name'];
        final sectionId = fileData['sectionId'];

        // Create file instance
        final file = File(filePath);
        if (!await file.exists()) {
          print('File does not exist: $filePath');
          continue;
        }

        // Generate unique name
        final uniqueFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$fileName';

        // Create storage reference
        final storageRef = FirebaseStorage.instance.ref().child(
            'organizations/$organizationId/programs/$programId/details/$sectionId/$uniqueFileName');

        // Start upload
        final uploadTask = storageRef.putFile(file);

        // Wait for upload to complete
        final snapshot = await uploadTask;

        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update the file data in our detail sections
        for (var section in detailSections) {
          if (section['id'].toString() == sectionId &&
              section['files'] != null) {
            final files = section['files'] as List;
            for (int i = 0; i < files.length; i++) {
              final currentFile = files[i] as Map<String, dynamic>;
              if (currentFile['name'] == fileName &&
                  currentFile['path'] == filePath &&
                  currentFile['isPending'] == true) {
                // Update the file with download URL and remove isPending flag
                files[i] = {
                  'name': fileName,
                  'downloadUrl': downloadUrl,
                  'uploadedAt': DateTime.now().toIso8601String(),
                };
                break;
              }
            }
          }
        }
      } catch (e) {
        print('Error uploading file: $e');
      }
    }
  }
}

class _DetailsEditorTabState extends State<DetailsEditorTab> {
  Map<String, bool> _uploadingFiles = {};
  int _nextDetailId = 0;
  final List<String> _detailTypes = ['paragraph', 'list', 'attachment'];

  // Add a map to store controllers for each list item
  final Map<String, TextEditingController> _listItemControllers = {};

  // Add a map to store controllers for paragraphs and list items to avoid recreation
  final Map<String, TextEditingController> _contentControllers = {};

  // Add tracking variables for upload progress
  bool _isUploading = false;
  String _uploadProgressMessage = '';
  int _totalFilesToUpload = 0;
  int _currentFileUploading = 0;

  // Add a map to track pending file uploads that haven't been saved to Firebase yet
  final Map<String, List<Map<String, dynamic>>> _pendingFileUploads = {};

  // Constructor to accept the key
  _DetailsEditorTabState({Key? key});

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

  void _removeDetailSection(int index) async {
    // Save the section before removing it
    final section = widget.detailSections[index];

    // Check if this is an attachment section
    if (section['type'] == 'attachment') {
      final files = section['files'] as List<dynamic>? ?? [];

      // Count how many files are actually stored in Firebase (have downloadUrl)
      final firebaseFiles = files
          .where((file) =>
              file['downloadUrl'] != null &&
              file['downloadUrl'].toString().isNotEmpty)
          .toList();

      // If there are Firebase files, show a confirmation dialog
      if (firebaseFiles.isNotEmpty) {
        bool confirmDelete = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete Attachment Section'),
                content: Text(
                    'This will permanently delete ${firebaseFiles.length} file(s) from storage. Continue?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ) ??
            false;

        if (!confirmDelete) return; // User canceled deletion

        // Show loading indicator
        setState(() {
          _isUploading = true;
          _uploadProgressMessage = 'Deleting files from storage...';
        });

        try {
          // Only delete files that have a downloadUrl (stored in Firebase)
          for (var fileData in firebaseFiles) {
            final downloadUrl = fileData['downloadUrl'];
            try {
              await _deleteFile(downloadUrl);
              print('Deleted file from Firebase: ${fileData['name']}');
            } catch (e) {
              print(
                  'Failed to delete file from Firebase: ${fileData['name']} - $e');
            }
          }
        } finally {
          // Hide loading indicator
          setState(() {
            _isUploading = false;
          });
        }
      }
    }

    // Proceed with removing the section from state
    // (this will remove any local files that weren't saved to Firebase)
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

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        setState(() {
          _uploadProgressMessage = 'Uploading: ${progress.toStringAsFixed(1)}%';
        });
      });

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

  // Add methods to move sections up and down
  void _moveDetailSectionUp(int index) {
    if (index <= 0) return; // Can't move up if it's the first item

    List<Map<String, dynamic>> updatedSections =
        List.from(widget.detailSections);
    final temp = updatedSections[index];
    updatedSections[index] = updatedSections[index - 1];
    updatedSections[index - 1] = temp;

    widget.updateDetailSections(updatedSections);
  }

  void _moveDetailSectionDown(int index) {
    if (index >= widget.detailSections.length - 1)
      return; // Can't move down if it's the last item

    List<Map<String, dynamic>> updatedSections =
        List.from(widget.detailSections);
    final temp = updatedSections[index];
    updatedSections[index] = updatedSections[index + 1];
    updatedSections[index + 1] = temp;

    widget.updateDetailSections(updatedSections);
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

        // Loading indicator - now showing either widget.isLoading OR _isUploading
        if (widget.isLoading || _isUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isUploading ? _uploadProgressMessage : 'Loading...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_isUploading) ...[
                    SizedBox(height: 8),
                    Text(
                      'Uploading $_currentFileUploading of $_totalFilesToUpload',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Build a detail section card
  Widget _buildDetailSectionCard(int index, Map<String, dynamic> section) {
    final type = section['type'] as String;
    final label = section['label'] as String;

    // Determine if this is the first or last item to disable buttons
    final isFirstItem = index == 0;
    final isLastItem = index == widget.detailSections.length - 1;

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

                      // Reordering buttons - reduced spacing
                      IconButton(
                        onPressed: isFirstItem
                            ? null
                            : () => _moveDetailSectionUp(index),
                        icon: Icon(Icons.arrow_upward,
                            size: 18,
                            color: isFirstItem
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 30, minHeight: 30),
                        tooltip: 'Move Up',
                      ),
                      // No SizedBox here to reduce space
                      IconButton(
                        onPressed: isLastItem
                            ? null
                            : () => _moveDetailSectionDown(index),
                        icon: Icon(Icons.arrow_downward,
                            size: 18,
                            color: isLastItem
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 30, minHeight: 30),
                        tooltip: 'Move Down',
                      ),
                      // Reduced spacing between button groups
                      SizedBox(width: 4),

                      // Edit and delete buttons - reduced spacing
                      IconButton(
                        onPressed: () => _showEditDetailDialog(index),
                        icon:
                            Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 30, minHeight: 30),
                        tooltip: 'Edit Section',
                      ),
                      // No SizedBox here to reduce space
                      IconButton(
                        onPressed: () => _removeDetailSection(index),
                        icon: Icon(Icons.delete,
                            size: 18, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 30, minHeight: 30),
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
    final sectionId = section['id'].toString();

    // Initialize pending uploads list for this section if needed
    _pendingFileUploads.putIfAbsent(sectionId, () => []);

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
          onPressed: _isUploading
              ? null
              : () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(allowMultiple: true);

                  if (result != null && result.files.isNotEmpty) {
                    // Create a copy of the current section
                    List<Map<String, dynamic>> updatedSections =
                        List.from(widget.detailSections);

                    // Initialize files array if needed
                    if (updatedSections[index]['files'] == null) {
                      updatedSections[index]['files'] = [];
                    }

                    // Process selected files
                    for (var pickedFile in result.files) {
                      if (pickedFile.path == null) continue;

                      final fileName = pickedFile.name;
                      final filePath = pickedFile.path!;

                      // Store file in pendingUploads
                      _pendingFileUploads[sectionId]!.add({
                        'name': fileName,
                        'path': filePath,
                        'sectionId': sectionId,
                      });

                      // Add a placeholder entry to the UI
                      (updatedSections[index]['files'] as List).add({
                        'name': fileName,
                        'path': filePath,
                        'isPending': true, // Mark as not uploaded yet
                      });
                    }

                    // Update the UI
                    widget.updateDetailSections(updatedSections);
                  }
                },
          icon: Icon(Icons.attach_file),
          label: Text('Upload Files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.grey[800],
          ),
        ),

        // Display files list
        if (files.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(
            'Files',
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
            final isPending = fileData['isPending'] == true;
            final downloadUrl = fileData['downloadUrl'];
            final isUploading = _uploadingFiles[fileName] ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  // File icon or loading indicator
                  isUploading
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isPending
                              ? Icons.hourglass_empty
                              : Icons.insert_drive_file,
                          size: 20,
                          color: isPending ? Colors.orange : Colors.blue,
                        ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            fileName,
                            style: TextStyle(
                              color: isPending ? Colors.grey[600] : Colors.blue,
                              decoration: isPending
                                  ? TextDecoration.none
                                  : TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPending)
                          Text(
                            '(Not uploaded yet - Save to upload)',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () async {
                      // Remove from UI
                      List<Map<String, dynamic>> updatedSections =
                          List.from(widget.detailSections);
                      (updatedSections[index]['files'] as List)
                          .removeAt(fileIndex);

                      // If it's a pending file, remove from pending uploads
                      if (isPending) {
                        // Find and remove from pending uploads
                        final pendingFiles =
                            _pendingFileUploads[sectionId] ?? [];
                        for (int i = 0; i < pendingFiles.length; i++) {
                          if (pendingFiles[i]['name'] == fileName) {
                            pendingFiles.removeAt(i);
                            break;
                          }
                        }
                      }
                      // If already uploaded, delete from Firebase
                      else if (downloadUrl != null) {
                        await _deleteFile(downloadUrl);
                      }

                      widget.updateDetailSections(updatedSections);
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

  // Add a method to handle uploading of pending files
  Future<void> _uploadPendingFiles() async {
    // Count total pending files
    int totalPending = 0;
    _pendingFileUploads.forEach((sectionId, files) {
      totalPending += files.length;
    });

    if (totalPending == 0) {
      return; // Nothing to upload
    }

    setState(() {
      _isUploading = true;
      _totalFilesToUpload = totalPending;
      _currentFileUploading = 0;
      _uploadProgressMessage = 'Preparing files for upload...';
    });

    try {
      // Process uploads section by section
      for (var sectionId in _pendingFileUploads.keys) {
        final sectionFiles = _pendingFileUploads[sectionId]!;
        if (sectionFiles.isEmpty) continue;

        // Find the section index
        int? sectionIndex;
        for (int i = 0; i < widget.detailSections.length; i++) {
          if (widget.detailSections[i]['id'].toString() == sectionId) {
            sectionIndex = i;
            break;
          }
        }

        if (sectionIndex == null) continue; // Section was deleted

        // Upload each file
        for (int i = 0; i < sectionFiles.length; i++) {
          final fileData = sectionFiles[i];
          final fileName = fileData['name'];
          final filePath = fileData['path'];

          setState(() {
            _currentFileUploading++;
            _uploadProgressMessage =
                'Uploading $_currentFileUploading of $_totalFilesToUpload: $fileName';
            _uploadingFiles[fileName] = true;
          });

          try {
            // Create a file instance from the path
            final file = File(filePath);

            // Upload to Firebase Storage
            final downloadUrl = await _uploadFile(file, 'section_$sectionId');

            if (downloadUrl != null) {
              // Update the sections with the download URL
              List<Map<String, dynamic>> updatedSections =
                  List.from(widget.detailSections);
              List<dynamic> files =
                  List.from(updatedSections[sectionIndex]['files'] ?? []);

              // Find the pending file in the list and update it
              for (int j = 0; j < files.length; j++) {
                final currentFile = files[j] as Map<String, dynamic>;
                if (currentFile['name'] == fileName &&
                    currentFile['isPending'] == true) {
                  files[j] = {
                    'name': fileName,
                    'downloadUrl': downloadUrl,
                    'uploadedAt': DateTime.now().toIso8601String(),
                    // Remove isPending and path properties
                  };
                  break;
                }
              }

              updatedSections[sectionIndex]['files'] = files;
              widget.updateDetailSections(updatedSections);
            }
          } catch (e) {
            print('Error uploading file: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error uploading $fileName: $e')),
            );
          } finally {
            setState(() {
              _uploadingFiles[fileName] = false;
            });
          }
        }

        // Clear processed files
        _pendingFileUploads[sectionId] = [];
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // **IMPORTANT**: Change this method to use async/await directly
  // so it can be called from the parent component
  Future<List<Map<String, dynamic>>> saveDetailSections() async {
    // First upload any pending files
    await _uploadPendingFiles();

    // Return the updated sections after files are uploaded
    return widget.detailSections;
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
