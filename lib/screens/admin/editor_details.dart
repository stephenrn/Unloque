import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'preview_details_program_page.dart';
import 'package:unloque/services/storage/firebase_storage_file_service.dart';
import 'package:unloque/models/organization_response_section.dart';

class DetailsEditorTab extends StatefulWidget {
  final String organizationId;
  final String programId;
  final List<ResponseSection> detailSections;
  final ValueChanged<List<ResponseSection>> updateDetailSections;
  final bool isLoading;

  DetailsEditorTab({
    super.key, // Use super.key instead of Key? key
    required this.organizationId,
    required this.programId,
    required this.detailSections,
    required this.updateDetailSections,
    required this.isLoading,
  });

  @override
  State<DetailsEditorTab> createState() => DetailsEditorTabState();
}

// Rename the state class to be public
class DetailsEditorTabState extends State<DetailsEditorTab> {
  Map<String, bool> _uploadingFiles = {};
  int _nextDetailId = 0;
  final List<String> _detailTypes = ['paragraph', 'list', 'attachment'];

  // Add a map to store controllers for paragraphs and list items to avoid recreation
  final Map<String, TextEditingController> _contentControllers = {};

  // Add tracking variables for upload progress
  bool _isUploading = false;
  String _uploadProgressMessage = '';
  int _totalFilesToUpload = 0;
  int _currentFileUploading = 0;

  @override
  void initState() {
    super.initState();
    _initNextDetailId();
    _initControllers();
  }

  // Initialize controllers for existing content
  void _initControllers() {
    for (var section in widget.detailSections) {
      if (section is ParagraphResponseSection) {
        final String key = 'paragraph_${section.id}';
        _contentControllers[key] = TextEditingController(text: section.content);
      } else if (section is ListResponseSection) {
        for (int i = 0; i < section.items.length; i++) {
          final String key = 'list_${section.id}_$i';
          _contentControllers[key] =
              TextEditingController(text: section.items[i].toString());
        }
      }
    }
  }

  @override
  void dispose() {
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
      final parsed = int.tryParse(section.id);
      if (parsed != null && parsed > highestId) {
        highestId = parsed;
      }
    }
    _nextDetailId = highestId + 1;
  }

  void _addDetailSection(String type) {
    final id = (_nextDetailId++).toString();
    const label = 'New Section';

    final ResponseSection newSection;
    if (type == 'paragraph') {
      newSection = ParagraphResponseSection(id: id, label: label, content: '');
    } else if (type == 'list') {
      newSection = ListResponseSection(
        id: id,
        label: label,
        items: const ['Enter an item'],
      );
    } else {
      newSection = AttachmentResponseSection(
        id: id,
        label: label,
        files: const <ResponseAttachmentFile>[],
      );
    }

    final updatedSections = List<ResponseSection>.from(widget.detailSections)
      ..add(newSection);
    widget.updateDetailSections(updatedSections);
  }

  void _removeDetailSection(int index) async {
    // Save the section before removing it
    final section = widget.detailSections[index];

    // Check if this is an attachment section
    if (section is AttachmentResponseSection) {
      final firebaseFiles = section.files
        .where((file) =>
          file.downloadUrl != null &&
          file.downloadUrl.toString().isNotEmpty)
        .toList(growable: false);

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
            false; // User canceled deletion

        if (!confirmDelete) return; // User canceled deletion

        // Show loading indicator
        setState(() {
          _isUploading = true;
          _uploadProgressMessage = 'Deleting files from storage...';
        });

        try {
          // Only delete files that have a downloadUrl (stored in Firebase)
          for (var fileData in firebaseFiles) {
            final downloadUrl = fileData.downloadUrl;
            if (downloadUrl == null) continue;
            try {
              await _deleteFile(downloadUrl);
              print('Deleted file from Firebase: ${fileData.name}');
            } catch (e) {
              print(
                  'Failed to delete file from Firebase: ${fileData.name} - $e');
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
    final updatedSections = List<ResponseSection>.from(widget.detailSections)
      ..removeAt(index);
    widget.updateDetailSections(updatedSections);
  }

  void _updateDetailSection(int index, ResponseSection newSection) {
    final updatedSections = List<ResponseSection>.from(widget.detailSections);
    updatedSections[index] = newSection;
    widget.updateDetailSections(updatedSections);
  }

  void _addListItem(int sectionIndex) {
    final section = widget.detailSections[sectionIndex];
    if (section is! ListResponseSection) return;

    final items = List<String>.from(section.items)..add('Enter an item');
    _updateDetailSection(sectionIndex, section.copyWith(items: items));
  }

  void _removeListItem(int sectionIndex, int itemIndex) {
    final section = widget.detailSections[sectionIndex];
    if (section is! ListResponseSection) return;

    final items = List<String>.from(section.items);

    // Remove the controller for the item being deleted
    final key = 'list_${section.id}_$itemIndex';
    if (_contentControllers.containsKey(key)) {
      _contentControllers[key]?.dispose();
      _contentControllers.remove(key);
    }

    // Remove the item
    items.removeAt(itemIndex);

    // Update controllers for all subsequent items (they shift down)
    for (int i = itemIndex; i < items.length; i++) {
      final oldKey = 'list_${section.id}_${i + 1}';
      final newKey = 'list_${section.id}_$i';

      if (_contentControllers.containsKey(oldKey)) {
        _contentControllers[newKey] = _contentControllers[oldKey]!;
        _contentControllers.remove(oldKey);
      }
    }

    _updateDetailSection(sectionIndex, section.copyWith(items: items));
  }

  void _updateListItem(int sectionIndex, int itemIndex, String newText) {
    final section = widget.detailSections[sectionIndex];
    if (section is! ListResponseSection) return;

    final items = List<String>.from(section.items);
    if (itemIndex < 0 || itemIndex >= items.length) return;

    items[itemIndex] = newText;
    _updateDetailSection(sectionIndex, section.copyWith(items: items));
  }

  // Method to upload file to Firebase Storage
  Future<String?> _uploadFile(File file, String sectionId) async {
    try {
      final fileName = path.basename(file.path);
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      return await FirebaseStorageFileService.uploadFile(
        storagePath:
            'organizations/${widget.organizationId}/programs/${widget.programId}/details/$sectionId/$uniqueFileName',
        file: file,
        onProgress: (percent) {
          setState(() {
            _uploadProgressMessage =
                'Uploading: ${percent.toStringAsFixed(1)}%';
          });
        },
      );
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Method to delete a file from Firebase Storage
  Future<void> _deleteFile(String downloadUrl) async {
    try {
      await FirebaseStorageFileService.deleteByDownloadUrl(downloadUrl);
    } catch (e) {
      print('Error deleting file from storage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  void _showEditDetailDialog(int index) {
    final section = widget.detailSections[index];
    final labelController = TextEditingController(text: section.label);
    final String selectedType = responseSectionTypeToString(section.type);

    // For paragraph type
    final contentController = TextEditingController(
      text: section is ParagraphResponseSection ? section.content : '');

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
                          initialValue: selectedType,
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
                          final updatedLabel = labelController.text;

                          if (section is ParagraphResponseSection) {
                            _updateDetailSection(
                              index,
                              section.copyWith(
                                label: updatedLabel,
                                content: contentController.text,
                              ),
                            );
                          } else {
                            _updateDetailSection(
                              index,
                              section.copyWith(label: updatedLabel),
                            );
                          }
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
                    initialValue: selectedType,
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

    List<ResponseSection> updatedSections =
      List.from(widget.detailSections);
    final temp = updatedSections[index];
    updatedSections[index] = updatedSections[index - 1];
    updatedSections[index - 1] = temp;

    widget.updateDetailSections(updatedSections);
  }

  void _moveDetailSectionDown(int index) {
    if (index >= widget.detailSections.length - 1)
      return; // Can't move down if it's the last item

    List<ResponseSection> updatedSections =
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
                        builder: (context) => PreviewProgramDetailsPage(
                          organizationId: widget.organizationId,
                          programId: widget.programId,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.visibility),
                  label: Text('Preview Saved Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
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
  Widget _buildDetailSectionCard(int index, ResponseSection section) {
    final type = responseSectionTypeToString(section.type);
    final label = section.label;

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
  Widget _buildSectionContent(int index, ResponseSection section) {
    if (section is ParagraphResponseSection) {
      return _buildParagraphContent(index, section);
    }
    if (section is ListResponseSection) {
      return _buildListContent(index, section);
    }
    if (section is AttachmentResponseSection) {
      return _buildAttachmentContent(index, section);
    }

    return const Text('Unknown section type');
  }

  // Build paragraph type content
  Widget _buildParagraphContent(int index, ParagraphResponseSection section) {
    final String key = 'paragraph_${section.id}';

    // Create controller if it doesn't exist
    if (!_contentControllers.containsKey(key)) {
      _contentControllers[key] =
          TextEditingController(text: section.content);
    }

    return TextField(
      maxLines: 6,
      decoration: InputDecoration(
        hintText: 'Enter text content here...',
        border: OutlineInputBorder(),
      ),
      controller: _contentControllers[key],
      onChanged: (value) {
        _updateDetailSection(index, section.copyWith(content: value));
      },
    );
  }

  // Build list type content
  Widget _buildListContent(int index, ListResponseSection section) {
    final items = section.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.asMap().entries.map((entry) {
          final itemIndex = entry.key;
          final item = entry.value;

          // Create a unique key for this list item
          final String key = 'list_${section.id}_$itemIndex';

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
  Widget _buildAttachmentContent(
      int index, AttachmentResponseSection section) {
    final files = section.files;

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
                    var updatedSection = section;

                    // Process selected files
                    for (var pickedFile in result.files) {
                      if (pickedFile.path == null) continue;

                      final fileName = pickedFile.name;
                      final filePath = pickedFile.path!;

                      updatedSection = updatedSection.copyWith(
                        files: List<ResponseAttachmentFile>.from(
                          updatedSection.files,
                        )
                          ..add(
                            ResponseAttachmentFile(
                              name: fileName,
                              localPath: filePath,
                              isPending: true,
                            ),
                          ),
                      );
                    }

                    // Update the UI
                    _updateDetailSection(index, updatedSection);
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
            final fileData = entry.value;
            final fileName = fileData.name;
            final isPending = fileData.isPending;
            final downloadUrl = fileData.downloadUrl;
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
                      final updatedFiles =
                          List<ResponseAttachmentFile>.from(section.files)
                            ..removeAt(fileIndex);

                      // If already uploaded, delete from Firebase
                      if (!isPending && downloadUrl != null) {
                        await _deleteFile(downloadUrl);
                      }

                      _updateDetailSection(
                        index,
                        section.copyWith(files: updatedFiles),
                      );
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
  Future<void> uploadPendingFiles() async {
    final pending = <({
      int sectionIndex,
      int fileIndex,
      String sectionId,
      ResponseAttachmentFile file,
    })>[];

    for (int sectionIndex = 0;
        sectionIndex < widget.detailSections.length;
        sectionIndex++) {
      final section = widget.detailSections[sectionIndex];
      if (section is! AttachmentResponseSection) continue;

      for (int fileIndex = 0; fileIndex < section.files.length; fileIndex++) {
        final file = section.files[fileIndex];
        if (!file.isPending) continue;
        if ((file.localPath ?? '').isEmpty) continue;
        pending.add((
          sectionIndex: sectionIndex,
          fileIndex: fileIndex,
          sectionId: section.id,
          file: file,
        ));
      }
    }

    if (pending.isEmpty) return;

    setState(() {
      _isUploading = true;
      _totalFilesToUpload = pending.length;
      _currentFileUploading = 0;
      _uploadProgressMessage = 'Preparing files for upload...';
    });

    try {
      for (final entry in pending) {
        final fileName = entry.file.name;
        final filePath = entry.file.localPath;
        if (filePath == null) continue;

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
            final downloadUrl =
                await _uploadFile(file, 'section_${entry.sectionId}');

            if (downloadUrl != null) {
              final section = widget.detailSections[entry.sectionIndex];
              if (section is AttachmentResponseSection) {
                final updatedFiles =
                    List<ResponseAttachmentFile>.from(section.files);
                if (entry.fileIndex >= 0 &&
                    entry.fileIndex < updatedFiles.length) {
                  updatedFiles[entry.fileIndex] =
                      updatedFiles[entry.fileIndex].copyWith(
                    downloadUrl: downloadUrl,
                    uploadedAt: DateTime.now().toIso8601String(),
                    isPending: false,
                    localPath: null,
                  );

                  _updateDetailSection(
                    entry.sectionIndex,
                    section.copyWith(files: updatedFiles),
                  );
                }
              }
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
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // **IMPORTANT**: Change this method to use async/await directly
  // so it can be called from the parent component
  Future<List<ResponseSection>> saveDetailSections() async {
    // First upload any pending files
    await uploadPendingFiles();

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

    // Update controllers if needed
    for (var section in widget.detailSections) {
      if (section is ParagraphResponseSection) {
        final String key = 'paragraph_${section.id}';
        if (!_contentControllers.containsKey(key)) {
          _contentControllers[key] =
              TextEditingController(text: section.content);
        }
      } else if (section is ListResponseSection) {
        for (int i = 0; i < section.items.length; i++) {
          final String key = 'list_${section.id}_$i';
          final itemText = section.items[i].toString();
          if (!_contentControllers.containsKey(key)) {
            _contentControllers[key] = TextEditingController(text: itemText);
          } else {
            final controller = _contentControllers[key]!;
            if (controller.text != itemText) {
              controller.text = itemText;
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
      if (section is ParagraphResponseSection) {
        neededKeys.add('paragraph_${section.id}');
      } else if (section is ListResponseSection) {
        for (int i = 0; i < section.items.length; i++) {
          neededKeys.add('list_${section.id}_$i');
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
