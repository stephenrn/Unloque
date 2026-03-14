import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'preview_response_program_page.dart';
import 'package:unloque/services/applications/organization_response_service.dart';
import 'package:path/path.dart' as path;
import 'package:unloque/services/storage/firebase_storage_file_service.dart';
import 'package:unloque/models/organization_response_section.dart';
import 'package:unloque/models/application_form_submission_field.dart';
import 'package:unloque/models/program_form_field.dart';

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
  List<ResponseSection> _responseSections = [];
  final List<String> _sectionTypes = ['paragraph', 'list', 'attachment'];
  bool _isUploading = false;

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

    final header = await OrganizationResponseService.fetchHeaderData(
      organizationId: organizationId?.toString(),
      programId: programId?.toString(),
    );

    programName = header['programName'] ?? '';
    orgName = header['orgName'] ?? '';
    logoUrl = header['logoUrl'] ?? '';
    deadline = header['deadline'] ?? '';
    category = header['category'] ?? '';

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
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final sectionType = responseSectionTypeFromString(type);
      switch (sectionType) {
        case ResponseSectionType.paragraph:
          _responseSections.add(
            ParagraphResponseSection(id: id, label: 'New Section', content: ''),
          );
          break;
        case ResponseSectionType.list:
          _responseSections.add(
            ListResponseSection(
              id: id,
              label: 'New Section',
              items: const ['Enter an item'],
            ),
          );
          break;
        case ResponseSectionType.attachment:
          _responseSections.add(
            AttachmentResponseSection(
              id: id,
              label: 'New Section',
              files: const <ResponseAttachmentFile>[],
            ),
          );
          break;
      }
    });
  }

  void _removeSection(int index) {
    setState(() {
      _responseSections.removeAt(index);
    });
  }

  void _setSection(int index, ResponseSection section) {
    setState(() {
      _responseSections[index] = section;
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
    final labelController = TextEditingController(text: section.label);
    final contentController = TextEditingController(
      text: section is ParagraphResponseSection ? section.content : '',
    );
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
            if (section.type == ResponseSectionType.paragraph) ...[
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
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final updatedLabel = labelController.text;
              if (section is ParagraphResponseSection) {
                _setSection(
                  index,
                  section.copyWith(
                    label: updatedLabel,
                    content: contentController.text,
                  ),
                );
              } else {
                _setSection(index, section.copyWith(label: updatedLabel));
              }
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addListItem(int sectionIndex) {
    final section = _responseSections[sectionIndex];
    if (section is! ListResponseSection) return;
    final nextItems = [...section.items, 'Enter an item'];
    _setSection(sectionIndex, section.copyWith(items: nextItems));
  }

  void _removeListItem(int sectionIndex, int itemIndex) {
    final section = _responseSections[sectionIndex];
    if (section is! ListResponseSection) return;
    final nextItems = List<String>.from(section.items);
    nextItems.removeAt(itemIndex);
    _setSection(sectionIndex, section.copyWith(items: nextItems));
  }

  Future<void> _pickFiles(int sectionIndex) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      final section = _responseSections[sectionIndex];
      if (section is! AttachmentResponseSection) return;

      final nextFiles = List<ResponseAttachmentFile>.from(section.files);
      for (final file in result.files) {
        nextFiles.add(
          ResponseAttachmentFile(
            name: file.name,
            localPath: file.path,
            isPending: true,
          ),
        );
      }
      _setSection(sectionIndex, section.copyWith(files: nextFiles));
    }
  }

  Future<String?> _uploadFile(File file, String sectionId) async {
    try {
      final fileName = path.basename(file.path);
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      return await FirebaseStorageFileService.uploadFile(
        storagePath:
            'organization_responses/${widget.application['organizationId']}/${widget.application['id']}/$sectionId/$uniqueFileName',
        file: file,
      );
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _uploadPendingFiles() async {
    int totalPending = 0;
    for (final section in _responseSections) {
      if (section is AttachmentResponseSection) {
        totalPending += section.files.where((f) => f.isPending).length;
      }
    }
    if (totalPending == 0) return;

    setState(() {
      _isUploading = true;
    });
    try {
      for (int sectionIndex = 0;
          sectionIndex < _responseSections.length;
          sectionIndex++) {
        final section = _responseSections[sectionIndex];
        if (section is! AttachmentResponseSection) continue;

        final nextFiles = List<ResponseAttachmentFile>.from(section.files);
        for (int fileIndex = 0; fileIndex < nextFiles.length; fileIndex++) {
          final fileData = nextFiles[fileIndex];
          if (!fileData.isPending) continue;
          final localPath = fileData.localPath;
          if (localPath == null || localPath.isEmpty) continue;

          final file = File(localPath);
          final downloadUrl = await _uploadFile(file, section.id);
          if (downloadUrl == null) continue;

          nextFiles[fileIndex] = fileData.copyWith(
            downloadUrl: downloadUrl,
            isPending: false,
            uploadedAt: DateTime.now().toIso8601String(),
          );
        }

        _setSection(sectionIndex, section.copyWith(files: nextFiles));
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
    });
    try {
      await _uploadPendingFiles();

      final orgId = widget.application['organizationId'] ??
          widget.application['orgId'];
      final userId = widget.application['userId'];
      final appId = widget.application['id'];
      final programId = widget.application['programId'] ?? appId;

      await OrganizationResponseService.sendResponse(
        organizationId: orgId?.toString(),
        userId: userId?.toString(),
        applicationId: appId?.toString(),
        programId: programId?.toString(),
        orgName: _orgName,
        programName: _programName,
        responseSections: _responseSections,
      );

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

  Widget _buildSectionCard(int index, ResponseSection section) {
    final type = responseSectionTypeToString(section.type);
    final label = section.label;
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

  Widget _buildSectionContent(int index, ResponseSection section) {
    switch (section) {
      case ParagraphResponseSection():
        // Use a controller to avoid the "typing backwards" bug.
        // Store controllers in a map by section index to persist state.
        _paragraphControllers ??= {};
        if (!_paragraphControllers!.containsKey(index)) {
          _paragraphControllers![index] =
              TextEditingController(text: section.content);
        } else {
          final controller = _paragraphControllers![index]!;
          final nextValue = section.content;
          if (controller.text != nextValue) {
            controller.text = nextValue;
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
          onChanged: (value) {
            _setSection(index, section.copyWith(content: value));
          },
        );
      case ListResponseSection():
        // For each item, use a controller per item to avoid typing issues.
        _listItemControllers ??= {};
        final items = section.items;
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
                        final nextItems = List<String>.from(items);
                        nextItems[itemIndex] = value;
                        _setSection(index, section.copyWith(items: nextItems));
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
      case AttachmentResponseSection():
        final files = section.files;
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
                final fileName = file.name;
                final isPending = file.isPending;
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
    }
  }

  Widget _buildSubmittedInfo(List<dynamic> formFields) {
    final submittedFields =
      ApplicationSubmittedFormField.listFromDynamic(formFields);

    final items = <Widget>[];
    for (final field in submittedFields) {
      switch (field.type) {
        case ProgramFormFieldType.shortAnswer:
        case ProgramFormFieldType.paragraph:
          items.add(_reviewField(field.label, field.answer ?? ''));
          break;
        case ProgramFormFieldType.multipleChoice:
          final selectedOption = field.selectedOption;
          if (selectedOption != null && selectedOption.isNotEmpty) {
            items.add(_reviewField(field.label, selectedOption));
          }
          break;
        case ProgramFormFieldType.checkbox:
          if (field.selectedOptions.isNotEmpty) {
            items.add(
              _reviewField(field.label, field.selectedOptions.join(', ')),
            );
          }
          break;
        case ProgramFormFieldType.date:
          if (field.selectedDate != null) {
            items.add(
              _reviewField(
                field.label,
                field.selectedDate!.toString().split(' ')[0],
              ),
            );
          }
          break;
        case ProgramFormFieldType.attachment:
          if (field.files.isNotEmpty) {
            items.add(_reviewAttachment(field.label, field.files));
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

  Widget _reviewAttachment(
      String label, List<ApplicationSubmittedAttachment> files) {
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
                final fileName =
                    file.name.isNotEmpty ? file.name : 'Unnamed File';
                final downloadUrl =
                    file.downloadUrl.isNotEmpty ? file.downloadUrl : null;
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

  String _getSubmittedDate(Map<String, dynamic> application) {
    final submittedAt = application['submittedAt'] ?? application['createdAt'];
    if (submittedAt == null) return '-';
    try {
      if (submittedAt is Timestamp) {
        return submittedAt.toDate().toString().split(' ')[0];
      }
      if (submittedAt is DateTime) {
        return submittedAt.toString().split(' ')[0];
      }
      if (submittedAt is String && submittedAt.length >= 10) {
        return submittedAt.substring(0, 10);
      }
    } catch (_) {}
    return '-';
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
                                          initialValue: selectedType,
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

}
