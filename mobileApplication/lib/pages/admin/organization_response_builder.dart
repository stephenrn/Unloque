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
    extends State<OrganizationResponseBuilderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _responseSections = [];
  final List<String> _sectionTypes = ['paragraph', 'list', 'attachment'];
  final Map<String, List<Map<String, dynamic>>> _pendingFileUploads = {};
  bool _isUploading = false;
  String _uploadProgressMessage = '';
  int _totalFilesToUpload = 0;
  int _currentFileUploading = 0;

  // Add state for fetched info
  String _programName = '';
  String _orgName = '';
  String _logoUrl = '';
  String _deadline = '';
  String _category = '';

  // Add controller maps to the state class
  Map<int, TextEditingController>? _paragraphControllers;
  Map<String, TextEditingController>? _listItemControllers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _responseSections = [];
    _fetchHeaderData();
  }

  Future<void> _fetchHeaderData() async {
    final app = widget.application;
    final programId = app['programId'] ?? app['id'];
    final organizationId = app['organizationId'] ?? app['orgId'];

    String programName = '';
    String orgName = '';
    String logoUrl = '';
    String deadline = '';
    String category = '';

    if (organizationId != null && programId != null) {
      // Fetch program info
      final programDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc(programId)
          .get();
      if (programDoc.exists) {
        final data = programDoc.data() ?? {};
        programName = (data['name'] ?? '').toString();
        deadline = (data['deadline'] ?? '').toString();
        category = (data['category'] ?? '').toString();
      }

      // Fetch organization info
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .get();
      if (orgDoc.exists) {
        final data = orgDoc.data() ?? {};
        orgName = (data['name'] ?? '').toString();
        logoUrl = (data['logoUrl'] ?? '').toString();
      }
    }

    // Fallback to application object if Firestore values are empty
    if (programName.isEmpty) programName = app['programName'] ?? '';
    if (orgName.isEmpty) orgName = app['organizationName'] ?? '';
    if (logoUrl.isEmpty) logoUrl = app['logoUrl'] ?? '';
    if (deadline.isEmpty) deadline = app['deadline'] ?? '';
    if (category.isEmpty) category = app['category'] ?? '';

    setState(() {
      _programName = programName;
      _orgName = orgName;
      _logoUrl = logoUrl;
      _deadline = deadline;
      _category = category;
    });
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

      // Add a notification for the user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Response Received',
        'message':
            'Organization $_orgName has responded to your application for $_programName',
        'type': 'response',
        'programId': widget.application['programId'] ?? appId,
        'programName': _programName,
        'organizationId': orgId,
        'organizationName': _orgName,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'applicationId': appId,
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
        // Use a controller to avoid the "typing backwards" bug.
        // Store controllers in a map by section index to persist state.
        _paragraphControllers ??= {};
        if (!_paragraphControllers!.containsKey(index)) {
          _paragraphControllers![index] =
              TextEditingController(text: section['content'] ?? '');
        } else {
          final controller = _paragraphControllers![index]!;
          if (controller.text != (section['content'] ?? '')) {
            controller.text = section['content'] ?? '';
            controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length));
          }
        }
        return TextField(
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Enter text content here...',
            border: OutlineInputBorder(),
          ),
          controller: _paragraphControllers![index],
          onChanged: (value) => _updateSection(index, {'content': value}),
        );
      case 'list':
        // For each item, use a controller per item to avoid typing issues.
        _listItemControllers ??= {};
        final items = List<String>.from(section['items'] ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;
              final ctrlKey = '$index-$itemIndex';
              if (!_listItemControllers!.containsKey(ctrlKey)) {
                _listItemControllers![ctrlKey] =
                    TextEditingController(text: item);
              } else if (_listItemControllers![ctrlKey]!.text != item) {
                _listItemControllers![ctrlKey]!.text = item;
                _listItemControllers![ctrlKey]!.selection =
                    TextSelection.fromPosition(TextPosition(
                        offset: _listItemControllers![ctrlKey]!.text.length));
              }
              return Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _listItemControllers![ctrlKey],
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

  Widget _buildReviewTab() {
    final app = widget.application;
    final userEmail = app['userEmail'] ?? app['userId'] ?? '';
    final userId = app['userId'] ?? '';
    final submittedAt = app['submittedAt'] ?? app['createdAt'];
    String submittedDate = '-';
    if (submittedAt != null) {
      try {
        if (submittedAt is Timestamp) {
          submittedDate = submittedAt.toDate().toString().split(' ')[0];
        } else if (submittedAt is DateTime) {
          submittedDate = submittedAt.toString().split(' ')[0];
        } else if (submittedAt is String && submittedAt.length >= 10) {
          submittedDate = submittedAt.substring(0, 10);
        }
      } catch (_) {}
    }
    final formFields = app['formFields'] ?? [];

    // Use fetched header info
    final programName = _programName;
    final orgName = _orgName;
    final logoUrl = _logoUrl;
    final deadline = _deadline;
    final category = _category;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: logoUrl.toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    logoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.business,
                                          color: Colors.grey[800]);
                                    },
                                  ),
                                )
                              : Icon(Icons.business, color: Colors.grey[800]),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                programName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                orgName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              // Email and User ID on a new line
                              if (userEmail.toString().isNotEmpty)
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (userId.toString().isNotEmpty)
                                Text(
                                  'User ID: $userId',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Colors.grey[800], size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Due: ',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800]),
                        ),
                        Text(
                          deadline.isNotEmpty ? deadline : 'No Deadline',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(width: 16),
                        Spacer(),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.isNotEmpty ? category : 'No Category',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 12, top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: Colors.grey[600], size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Submitted: $submittedDate',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Add "Submitted Information" title above the card
          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Submitted Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: formFields == null ||
                        (formFields is List && formFields.isEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No form data submitted.',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                        ),
                      )
                    : _buildSubmittedInfo(formFields),
              ),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubmittedInfo(List<dynamic> formFields) {
    List<Widget> items = [];
    for (var field in formFields) {
      if (field is! Map) continue;
      final type = field['type'] ?? '';
      final label = field['label'] ?? '';
      switch (type) {
        case 'short_answer':
        case 'paragraph':
          items.add(_reviewField(label, field['answer'] ?? ''));
          break;
        case 'multiple_choice':
          if ((field['selectedOption'] ?? '').toString().isNotEmpty) {
            items.add(_reviewField(label, field['selectedOption'].toString()));
          }
          break;
        case 'checkbox':
          final selected = field['selectedOptions'];
          if (selected is List && selected.isNotEmpty) {
            items.add(_reviewField(label, selected.join(', ')));
          }
          break;
        case 'date':
          final date = field['selectedDate'];
          if (date != null) {
            items.add(_reviewField(label, date.toString().split('T')[0]));
          }
          break;
        case 'attachment':
          final files = field['files'];
          if (files is List && files.isNotEmpty) {
            items.add(_reviewAttachment(label, files));
          }
          break;
      }
    }
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No form data submitted.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _reviewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewAttachment(String label, List files) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: files.map<Widget>((file) {
                final fileName = file['name'] ?? 'Unnamed File';
                final downloadUrl = file['downloadUrl'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file,
                          size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                downloadUrl != null ? Colors.blue : Colors.grey,
                            decoration: downloadUrl != null
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  AppBar(
                    backgroundColor: Colors.grey[100],
                    automaticallyImplyLeading: false,
                    elevation: 0,
                    toolbarHeight: 60,
                    titleSpacing: 0,
                    title: SizedBox.shrink(),
                    actions: [
                      _isUploading
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.grey[800])),
                            )
                          : IconButton(
                              icon: Icon(Icons.send, color: Colors.grey[800]),
                              tooltip: 'Send Response',
                              onPressed: _isUploading ? null : _sendResponse,
                            ),
                    ],
                  ),
                  // Centered title
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Review and Response',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Back button (left)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Container(
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
                  ),
                ],
              ),
              // (TabBar removed from here)
            ],
          ),
        ),
      ),
      // Move TabBar into the body, above the TabBarView
      body: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.grey[800],
                unselectedLabelColor: Colors.grey[500],
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Review'),
                  Tab(text: 'Response'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- REVIEW TAB ---
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header Card
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ...existing header content...
                                // (see _buildReviewTab for details)
                                // ...existing code...
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: _logoUrl.toString().isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  _logoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Icon(Icons.business,
                                                        color:
                                                            Colors.grey[800]);
                                                  },
                                                ),
                                              )
                                            : Icon(Icons.business,
                                                color: Colors.grey[800]),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _programName,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _orgName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            if ((widget.application[
                                                        'userEmail'] ??
                                                    '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                widget.application['userEmail'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if ((widget.application['userId'] ??
                                                    '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                'User ID: ${widget.application['userId']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          color: Colors.grey[800], size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Due: ',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800]),
                                      ),
                                      Text(
                                        _deadline.isNotEmpty
                                            ? _deadline
                                            : 'No Deadline',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _category.isNotEmpty
                                              ? _category
                                              : 'No Category',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, bottom: 12, top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          color: Colors.grey[600], size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Submitted: ${_getSubmittedDate(widget.application)}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Submitted Information Title
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 0, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Submitted Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                        // Submitted Info Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildSubmittedInfo(
                                  widget.application['formFields'] ?? []),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // --- RESPONSE TAB ---
                  SingleChildScrollView(
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add spacing at the top of the preview response button
                            SizedBox(height: 16),
                            // Preview Button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PreviewResponseProgramPage(
                                        responseSections: _responseSections,
                                        application: widget.application,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.visibility),
                                label: Text('Preview Response'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // Response Sections
                            ..._responseSections
                                .asMap()
                                .entries
                                .map((entry) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0),
                                      child: _buildSectionCard(
                                          entry.key, entry.value),
                                    )),
                            SizedBox(height: 16),
                            // Add Section Button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  String selectedType = 'paragraph';
                                  showDialog(
                                    context: context,
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, setDialogState) =>
                                          AlertDialog(
                                        title: Text('Add Response Section'),
                                        content:
                                            DropdownButtonFormField<String>(
                                          value: selectedType,
                                          items: _sectionTypes.map((type) {
                                            String displayText =
                                                type[0].toUpperCase() +
                                                    type.substring(1);
                                            return DropdownMenuItem(
                                                value: type,
                                                child: Text(displayText));
                                          }).toList(),
                                          onChanged: (value) => setDialogState(
                                              () => selectedType = value!),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.grey[800],
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                        if (_isUploading)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get submitted date string
  String _getSubmittedDate(Map<String, dynamic> app) {
    final submittedAt = app['submittedAt'] ?? app['createdAt'];
    if (submittedAt == null) return '-';
    try {
      if (submittedAt is Timestamp) {
        return submittedAt.toDate().toString().split(' ')[0];
      } else if (submittedAt is DateTime) {
        return submittedAt.toString().split(' ')[0];
      } else if (submittedAt is String && submittedAt.length >= 10) {
        return submittedAt.substring(0, 10);
      }
    } catch (_) {}
    return '-';
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _paragraphControllers?.forEach((_, c) => c.dispose());
    _listItemControllers?.forEach((_, c) => c.dispose());
    super.dispose();
  }
}
