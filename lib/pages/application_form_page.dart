import 'package:flutter/material.dart';
import 'package:unloque/pages/application_details_page.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ApplicationFormPage extends StatefulWidget {
  final Map<String, dynamic> application;

  const ApplicationFormPage({super.key, required this.application});

  @override
  _ApplicationFormPageState createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  String? selectedOption; // For multiple-choice selection
  Map<String, bool> checkboxValues = {}; // For checkbox selections
  Map<String, DateTime?> selectedDates = {}; // For date selections
  Map<String, List<Map<String, dynamic>>> attachedFilesMap =
      {}; // For attachments with URLs
  Map<String, TextEditingController> textControllers =
      {}; // For short answer and paragraph inputs

  // Track files being uploaded
  Map<String, bool> uploadingFiles = {};
  bool isSaving = false;
  bool isUploadingFiles = false;
  String uploadProgressMessage = '';
  int totalFilesToUpload = 0;
  int currentFileUploadIndex = 0;

  @override
  void initState() {
    super.initState();
    final forms = widget.application['details']['forms'] ?? [];
    for (var form in forms) {
      if (form['type'] == 'checkbox') {
        for (var option in form['options']) {
          if (!checkboxValues.containsKey(option)) {
            checkboxValues[option] = false; // Ensure default value is false
          }
        }
      } else if (form['type'] == 'date') {
        selectedDates[form['label']] = null; // Initialize dates as null
      } else if (form['type'] == 'attachment') {
        attachedFilesMap[form['label']] = []; // Ensure non-null list
      } else if (form['type'] == 'short_answer' ||
          form['type'] == 'paragraph') {
        textControllers[form['label']] =
            TextEditingController(); // Initialize text controllers
      }
    }
    loadFormData(); // Load saved form data when the page is initialized
  }

  Future<void> saveFormData() async {
    setState(() {
      isSaving = true;
      isUploadingFiles = false;
      uploadProgressMessage = 'Preparing to save...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('You must be signed in to save data'),
            backgroundColor: Colors.red));
        return;
      }

      // Count total files that need uploading
      totalFilesToUpload = 0;
      for (var label in attachedFilesMap.keys) {
        for (var fileData in attachedFilesMap[label]!) {
          if (fileData['path'] != null &&
              (fileData['downloadUrl'] == null ||
                  !fileData['path'].toString().startsWith('http'))) {
            totalFilesToUpload++;
          }
        }
      }

      currentFileUploadIndex = 0;

      // Only set uploading state if we have files to upload
      if (totalFilesToUpload > 0) {
        setState(() {
          isUploadingFiles = true;
          uploadProgressMessage = 'Uploading files (0/$totalFilesToUpload)';
        });
      }

      // Now upload files one by one
      for (var label in attachedFilesMap.keys) {
        for (int i = 0; i < attachedFilesMap[label]!.length; i++) {
          final fileData = attachedFilesMap[label]![i];
          // If this file has a path but no downloadUrl, upload it
          if (fileData['path'] != null &&
              (fileData['downloadUrl'] == null ||
                  !fileData['path'].toString().startsWith('http'))) {
            try {
              final file = File(fileData['path']);
              if (!await file.exists()) {
                print('File does not exist: ${fileData['path']}');
                continue;
              }

              currentFileUploadIndex++;
              setState(() {
                uploadProgressMessage =
                    'Uploading files ($currentFileUploadIndex/$totalFilesToUpload)';
              });

              // Generate a unique file path in storage with timestamp to avoid conflicts
              final fileName =
                  '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
              final storageRef = FirebaseStorage.instance.ref().child(
                  'users/${user.uid}/applications/${widget.application['id']}/$label/$fileName');

              // Upload file with retry logic
              UploadTask? uploadTask;
              try {
                uploadTask = storageRef.putFile(file);
                final snapshot = await uploadTask;
                final downloadUrl = await snapshot.ref.getDownloadURL();

                // Update the file data with the download URL
                setState(() {
                  attachedFilesMap[label]![i] = {
                    'name': fileData['name'],
                    'path': fileData['path'], // Keep local path for cache
                    'downloadUrl': downloadUrl, // Store download URL
                  };
                });
                print(
                    'Successfully uploaded file: ${fileData['name']} with URL: $downloadUrl');
              } catch (uploadError) {
                print('Error uploading file: $uploadError');
                // Continue to next file instead of failing the entire save
                continue;
              }
            } catch (fileError) {
              print('Error processing file: $fileError');
              // Continue to next file
              continue;
            }
          }
        }
      }

      setState(() {
        isUploadingFiles = false;
        uploadProgressMessage = 'Saving form data...';
      });

      // Now save all form data including updated file information
      final formData = {
        'short_answers': textControllers
            .map((key, controller) => MapEntry(key, controller.text)),
        'paragraphs': textControllers
            .map((key, controller) => MapEntry(key, controller.text)),
        'multiple_choice': selectedOption,
        'checkboxes': checkboxValues,
        'dates': selectedDates
            .map((key, value) => MapEntry(key, value?.toIso8601String())),
        'attachments': attachedFilesMap,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('users-application')
          .doc(widget.application['id'])
          .update({'form_data': formData});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error saving form data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
        isUploadingFiles = false;
      });
    }
  }

  Future<void> loadFormData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('users-application')
          .doc(widget.application['id'])
          .get();

      if (doc.exists && doc.data() != null) {
        final formData = doc.data()!['form_data'] ?? {};

        setState(() {
          selectedOption = formData['multiple_choice'];
          checkboxValues = Map<String, bool>.from(formData['checkboxes'] ?? {});

          selectedDates = Map<String, DateTime?>.from(
            (formData['dates'] ?? {}).map((key, value) => MapEntry(
                  key,
                  value != null ? DateTime.parse(value) : null,
                )),
          );

          // Load attachments with their download URLs
          if (formData['attachments'] != null) {
            final storedAttachments =
                formData['attachments'] as Map<String, dynamic>;
            for (var key in storedAttachments.keys) {
              attachedFilesMap[key] = [];
              final files = storedAttachments[key] as List<dynamic>;
              for (var file in files) {
                attachedFilesMap[key]!.add(Map<String, dynamic>.from(file));
              }
            }
          }

          textControllers.forEach((key, controller) {
            controller.text = formData['short_answers']?[key] ?? '';
          });
        });
      }
    } catch (error) {
      print('Error loading form data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading saved data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to download a file when needed
  Future<void> downloadAndOpenFile(Map<String, dynamic> fileData) async {
    final fileName = fileData['name'];
    final downloadUrl = fileData['downloadUrl'];

    if (downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No download URL available for this file')),
      );
      return;
    }

    setState(() {
      uploadingFiles[fileName] = true;
    });

    try {
      // Check if file exists in local cache
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/$fileName';
      final localFile = File(localPath);

      // If file doesn't exist locally, download it
      if (!await localFile.exists()) {
        final response = await http.get(Uri.parse(downloadUrl));
        await localFile.writeAsBytes(response.bodyBytes);
      }

      // Open the file
      await OpenFilex.open(localPath);
    } catch (error) {
      print('Error downloading/opening file: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        uploadingFiles[fileName] = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDates[label]) {
      setState(() {
        selectedDates[label] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final forms = widget.application['details']['forms'] ?? [];

    // Pre-initialize all checkbox values before rendering
    for (var form in forms) {
      if (form['type'] == 'checkbox') {
        for (var option in form['options']) {
          checkboxValues.putIfAbsent(option, () => false);
        }
      }
    }

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
              Expanded(
                child: Center(
                  child: Text(
                    isSaving ? uploadProgressMessage : 'Application Form',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              isSaving
                  ? Container(
                      width: 48,
                      height: 48,
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: saveFormData,
                      icon: Icon(Icons.save, color: Colors.grey[800]),
                      tooltip: 'Save Form',
                    ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Existing content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.application['categoryColor'],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey[800] ?? Colors.black,
                            width: 0.5),
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
                                  child: Icon(
                                    widget.application['organizationLogo'] ??
                                        Icons
                                            .help_outline, // Provide a default value
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.application['programName'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      widget.application['organizationName'] ??
                                          'Unknown Organization',
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                            text: widget
                                                    .application['deadline'] ??
                                                'No Deadline', // Handle null deadline
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
                                  widget.application['category'] ??
                                      'Unknown Category', // Handle null category
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
                  // Forms Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey[800] ?? Colors.black,
                            width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: forms.map<Widget>((form) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Render each form question
                                if (form['type'] == 'short_answer' ||
                                    form['type'] == 'paragraph') ...[
                                  Text(
                                    form['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    controller: textControllers[form['label']],
                                    maxLines:
                                        form['type'] == 'paragraph' ? 5 : 1,
                                    decoration: InputDecoration(
                                      hintText: form['placeholder'],
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ] else if (form['type'] ==
                                    'multiple_choice') ...[
                                  Text(
                                    form['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ...form['options'].map<Widget>((option) {
                                    return RadioListTile(
                                      value: option,
                                      groupValue: selectedOption,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedOption = value as String?;
                                        });
                                      },
                                      title: Text(option),
                                    );
                                  }).toList(),
                                ] else if (form['type'] == 'checkbox') ...[
                                  Text(
                                    form['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ...form['options'].map<Widget>((option) {
                                    // Make sure the value is never null
                                    final bool isChecked =
                                        checkboxValues[option] ?? false;

                                    return CheckboxListTile(
                                      value: isChecked,
                                      tristate: false,
                                      onChanged: (value) {
                                        setState(() {
                                          checkboxValues[option] =
                                              value ?? false;
                                        });
                                      },
                                      title: Text(option),
                                    );
                                  }).toList(),
                                ] else if (form['type'] == 'date') ...[
                                  Text(
                                    form['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    decoration: InputDecoration(
                                      hintText: selectedDates[form['label']] ==
                                              null
                                          ? 'Select a date'
                                          : '${selectedDates[form['label']]!.toLocal()}'
                                              .split(' ')[0],
                                      border: OutlineInputBorder(),
                                    ),
                                    readOnly: true,
                                    onTap: () =>
                                        _selectDate(context, form['label']),
                                  ),
                                ] else if (form['type'] == 'attachment') ...[
                                  Text(
                                    form['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      FilePickerResult? result =
                                          await FilePicker.platform
                                              .pickFiles(allowMultiple: true);
                                      if (result != null) {
                                        final appDir =
                                            await getApplicationDocumentsDirectory();
                                        for (var file in result.files) {
                                          final filePath = file.path!;
                                          final fileName = file.name;

                                          try {
                                            if (filePath.startsWith('http')) {
                                              // Download file from external URL
                                              final response = await http
                                                  .get(Uri.parse(filePath));
                                              final localFile = File(
                                                  '${appDir.path}/$fileName');
                                              await localFile.writeAsBytes(
                                                  response.bodyBytes);
                                              setState(() {
                                                attachedFilesMap[form['label']]!
                                                    .add({
                                                  'name': fileName,
                                                  'path': localFile.path,
                                                  // downloadUrl will be added when saving
                                                });
                                              });
                                            } else {
                                              // Copy local file to app documents directory
                                              final localFile =
                                                  await File(filePath).copy(
                                                      '${appDir.path}/$fileName');
                                              setState(() {
                                                attachedFilesMap[form['label']]!
                                                    .add({
                                                  'name': fileName,
                                                  'path': localFile.path,
                                                  // downloadUrl will be added when saving
                                                });
                                              });
                                            }
                                          } catch (error) {
                                            print(
                                                'Error processing file: $error');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error processing file: $fileName'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    icon: Icon(Icons.attach_file),
                                    label: Text('Upload Files'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.grey[300] ?? Colors.grey,
                                      foregroundColor:
                                          Colors.grey[800] ?? Colors.black,
                                    ),
                                  ),
                                  if (attachedFilesMap[form['label']] != null &&
                                      attachedFilesMap[form['label']]!
                                          .isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: attachedFilesMap[form['label']]!
                                          .map((fileData) {
                                        final fileName =
                                            fileData['name'] ?? 'Unnamed File';
                                        final isUploading =
                                            uploadingFiles[fileName] ?? false;

                                        return Row(
                                          children: [
                                            if (isUploading)
                                              Container(
                                                width: 24,
                                                height: 24,
                                                padding: EdgeInsets.all(4),
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            else
                                              Icon(Icons.insert_drive_file,
                                                  size: 20, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final downloadUrl =
                                                      fileData['downloadUrl'];
                                                  final localPath =
                                                      fileData['path'];

                                                  // If we have a local path and file exists, open directly
                                                  if (localPath != null) {
                                                    try {
                                                      final file =
                                                          File(localPath);
                                                      if (await file.exists()) {
                                                        await OpenFilex.open(
                                                            localPath);
                                                        return;
                                                      }
                                                    } catch (e) {
                                                      print(
                                                          'Error checking local file: $e');
                                                    }
                                                  }

                                                  // Otherwise download using the URL
                                                  if (downloadUrl != null) {
                                                    await downloadAndOpenFile(
                                                        fileData);
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'File not available yet. Save the form first.'),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  fileName,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  attachedFilesMap[
                                                          form['label']]!
                                                      .remove(fileData);
                                                });
                                              },
                                              icon: Icon(Icons.close,
                                                  color: Colors.red, size: 20),
                                              tooltip: 'Remove file',
                                              constraints: BoxConstraints(
                                                  minWidth: 40, minHeight: 40),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                                SizedBox(
                                    height:
                                        24), // Add spacing between questions
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay for file uploads
          if (isUploadingFiles)
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
                    Text(
                      uploadProgressMessage,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'Please don\'t close the app',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // Handle form submission
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: darkenColor(widget.application['categoryColor']!),
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
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
