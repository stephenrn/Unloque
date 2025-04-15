import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'preview_response_program_page.dart';

class OrganizationResponseBuilderPage extends StatefulWidget {
  final Map<String, dynamic> application;
  const OrganizationResponseBuilderPage({Key? key, required this.application})
      : super(key: key);

  @override
  State<OrganizationResponseBuilderPage> createState() =>
      _OrganizationResponseBuilderPageState();
}

class _OrganizationResponseBuilderPageState
    extends State<OrganizationResponseBuilderPage> {
  List<Map<String, dynamic>> _responseSections = [];
  final List<String> _sectionTypes = ['paragraph', 'list', 'attachment'];
  final Map<String, List<Map<String, dynamic>>> _pendingFileUploads = {};
  bool _isUploading = false;
  String _uploadProgressMessage = '';
  int _totalFilesToUpload = 0;
  int _currentFileUploading = 0;

  @override
  void initState() {
    super.initState();
    _responseSections = [];
  }

  void _addSection(String type) {
    setState(() {
      final id = DateTime.now().millisecondsSinceEpoch;
      Map<String, dynamic> section = {
        'id': id,
        'type': type,
        'label': 'New Section',
      };
      if (type == 'paragraph') {
        section['content'] = '';
      } else if (type == 'list') {
        section['items'] = ['Enter an item'];
      } else if (type == 'attachment') {
        section['files'] = [];
      }
      _responseSections.add(section);
    });
  }

  void _removeSection(int index) {
    setState(() {
      _responseSections.removeAt(index);
    });
  }

  void _updateSection(int index, Map<String, dynamic> newData) {
    setState(() {
      _responseSections[index] = {..._responseSections[index], ...newData};
    });
  }

  void _moveSectionUp(int index) {
    if (index <= 0) return;
    setState(() {
      final temp = _responseSections[index - 1];
      _responseSections[index - 1] = _responseSections[index];
      _responseSections[index] = temp;
    });
  }

  void _moveSectionDown(int index) {
    if (index >= _responseSections.length - 1) return;
    setState(() {
      final temp = _responseSections[index + 1];
      _responseSections[index + 1] = _responseSections[index];
      _responseSections[index] = temp;
    });
  }

  void _editSectionDialog(int index) {
    final section = _responseSections[index];
    final labelController = TextEditingController(text: section['label']);
    final contentController =
        TextEditingController(text: section['content'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(labelText: 'Section Label'),
            ),
            if (section['type'] == 'paragraph') ...[
              SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: InputDecoration(labelText: 'Content'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newData = {'label': labelController.text};
              if (section['type'] == 'paragraph') {
                newData['content'] = contentController.text;
              }
              _updateSection(index, newData);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addListItem(int sectionIndex) {
    setState(() {
      (_responseSections[sectionIndex]['items'] as List).add('Enter an item');
    });
  }

  void _removeListItem(int sectionIndex, int itemIndex) {
    setState(() {
      (_responseSections[sectionIndex]['items'] as List).removeAt(itemIndex);
    });
  }

  Future<void> _pickFiles(int sectionIndex) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        if (_responseSections[sectionIndex]['files'] == null) {
          _responseSections[sectionIndex]['files'] = [];
        }
        for (var file in result.files) {
          _responseSections[sectionIndex]['files'].add({
            'name': file.name,
            'path': file.path,
            'isPending': true,
          });
          _pendingFileUploads['${_responseSections[sectionIndex]['id']}'] ??=
              [];
          _pendingFileUploads['${_responseSections[sectionIndex]['id']}']!.add({
            'name': file.name,
            'path': file.path,
            'sectionId': _responseSections[sectionIndex]['id'].toString(),
          });
        }
      });
    }
  }

  Future<String?> _uploadFile(File file, String sectionId) async {
    try {
      final fileName = path.basename(file.path);
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storageRef = FirebaseStorage.instance.ref().child(
          'organization_responses/${widget.application['organizationId']}/${widget.application['id']}/$sectionId/$uniqueFileName');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _uploadPendingFiles() async {
    int totalPending = 0;
    _pendingFileUploads.forEach((_, files) => totalPending += files.length);
    if (totalPending == 0) return;
    setState(() {
      _isUploading = true;
      _totalFilesToUpload = totalPending;
      _currentFileUploading = 0;
      _uploadProgressMessage = 'Uploading files...';
    });
    try {
      for (var sectionId in _pendingFileUploads.keys) {
        final sectionFiles = _pendingFileUploads[sectionId]!;
        if (sectionFiles.isEmpty) continue;
        int? sectionIndex = _responseSections
            .indexWhere((s) => s['id'].toString() == sectionId);
        if (sectionIndex == -1) continue;
        for (var fileData in sectionFiles) {
          _currentFileUploading++;
          setState(() {
            _uploadProgressMessage =
                'Uploading $_currentFileUploading of $_totalFilesToUpload: ${fileData['name']}';
          });
          final file = File(fileData['path']);
          final downloadUrl = await _uploadFile(file, sectionId);
          if (downloadUrl != null) {
            List files = List.from(_responseSections[sectionIndex]['files']);
            for (int j = 0; j < files.length; j++) {
              if (files[j]['name'] == fileData['name'] &&
                  files[j]['isPending'] == true) {
                files[j] = {
                  'name': fileData['name'],
                  'downloadUrl': downloadUrl,
                  'uploadedAt': DateTime.now().toIso8601String(),
                };
                break;
              }
            }
            _responseSections[sectionIndex]['files'] = files;
          }
        }
        _pendingFileUploads[sectionId] = [];
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _sendResponse() async {
    setState(() {
      _isUploading = true;
      _uploadProgressMessage = 'Sending response...';
    });
    try {
      await _uploadPendingFiles();
      final orgId = widget.application['organizationId'];
      final userId = widget.application['userId'];
      final appId = widget.application['id'];
      final userAppRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users-application')
          .doc(appId);

      await userAppRef.update({
        'organizationResponse': {
          'organizationId': orgId,
          'userId': userId,
          'applicationId': appId,
          'responseSections': _responseSections,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'status': 'Completed',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Response sent and application marked as completed!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('Error sending response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error sending response: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildSectionCard(int index, Map<String, dynamic> section) {
    final type = section['type'];
    final label = section['label'];
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(type[0].toUpperCase() + type.substring(1)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[700]),
                  tooltip: 'Edit Section',
                  onPressed: () => _editSectionDialog(index),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_upward,
                      color: index == 0 ? Colors.grey[300] : Colors.grey[700]),
                  tooltip: 'Move Up',
                  onPressed: index == 0 ? null : () => _moveSectionUp(index),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_downward,
                      color: index == _responseSections.length - 1
                          ? Colors.grey[300]
                          : Colors.grey[700]),
                  tooltip: 'Move Down',
                  onPressed: index == _responseSections.length - 1
                      ? null
                      : () => _moveSectionDown(index),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Section',
                  onPressed: () => _removeSection(index),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSectionContent(index, section),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(int index, Map<String, dynamic> section) {
    switch (section['type']) {
      case 'paragraph':
        return TextField(
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Enter text content here...',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: section['content'] ?? ''),
          onChanged: (value) => _updateSection(index, {'content': value}),
        );
      case 'list':
        final items = List<String>.from(section['items'] ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;
              return Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: item),
                      decoration: InputDecoration(
                        hintText: 'Enter list item',
                        border: UnderlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 8),
                      ),
                      onChanged: (value) {
                        final newItems = List<String>.from(items);
                        newItems[itemIndex] = value;
                        _updateSection(index, {'items': newItems});
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: items.length > 1
                        ? () => _removeListItem(index, itemIndex)
                        : null,
                  ),
                ],
              );
            }),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _addListItem(index),
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Item'),
            ),
          ],
        );
      case 'attachment':
        final files = List<Map<String, dynamic>>.from(section['files'] ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : () => _pickFiles(index),
              icon: Icon(Icons.attach_file),
              label: Text('Upload Files'),
            ),
            if (files.isNotEmpty) ...[
              SizedBox(height: 8),
              ...files.map((file) {
                final fileName = file['name'] ?? 'Unnamed File';
                final isPending = file['isPending'] == true;
                return Row(
                  children: [
                    Icon(
                        isPending
                            ? Icons.hourglass_empty
                            : Icons.insert_drive_file,
                        size: 20,
                        color: isPending ? Colors.orange : Colors.blue),
                    SizedBox(width: 8),
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
                  ],
                );
              }),
            ],
          ],
        );
      default:
        return Text('Unknown section type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization Response Builder'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        actions: [
          _isUploading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                )
              : IconButton(
                  icon: Icon(Icons.send),
                  tooltip: 'Send Response',
                  onPressed: _isUploading ? null : _sendResponse,
                ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreviewResponseProgramPage(
                            responseSections: _responseSections,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility),
                    label: Text('Preview Response'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ..._responseSections
                    .asMap()
                    .entries
                    .map((entry) => _buildSectionCard(entry.key, entry.value)),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      String selectedType = 'paragraph';
                      showDialog(
                        context: context,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setDialogState) => AlertDialog(
                            title: Text('Add Response Section'),
                            content: DropdownButtonFormField<String>(
                              value: selectedType,
                              items: _sectionTypes.map((type) {
                                String displayText =
                                    type[0].toUpperCase() + type.substring(1);
                                return DropdownMenuItem(
                                    value: type, child: Text(displayText));
                              }).toList(),
                              onChanged: (value) =>
                                  setDialogState(() => selectedType = value!),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  _addSection(selectedType);
                                  Navigator.pop(context);
                                },
                                child: Text('Add'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Response Section'),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 16),
                    Text(_uploadProgressMessage,
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
