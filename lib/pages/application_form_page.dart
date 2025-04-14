import 'package:flutter/material.dart';
import 'package:unloque/pages/application_details_page.dart';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:unloque/pages/application_pending_page.dart';

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

  // Track files to be deleted from storage when saving
  Set<String> filesToDelete = {}; // Stores download URLs of files to be deleted

  // Track original state of files
  Map<String, List<Map<String, dynamic>>> originalAttachedFilesMap = {};

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

      // First, delete files that were removed by the user
      if (filesToDelete.isNotEmpty) {
        setState(() {
          uploadProgressMessage = 'Removing deleted files...';
        });

        for (String downloadUrl in filesToDelete) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(downloadUrl);
            await ref.delete();
            print('Successfully deleted file with URL: $downloadUrl');
          } catch (e) {
            print('Error deleting file from storage: $e');
          }
        }
        filesToDelete.clear();
      }

      // Count total files that need uploading
      totalFilesToUpload = 0;
      for (var label in attachedFilesMap.keys) {
        for (var fileData in attachedFilesMap[label]!) {
          if (fileData['path'] != null &&
              (fileData['downloadUrl'] == null ||
                  fileData['downloadUrl'].toString().isEmpty)) {
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

      // Create a deep copy of the attachedFilesMap to store updated data
      final updatedAttachedFilesMap = <String, List<Map<String, dynamic>>>{};
      for (var label in attachedFilesMap.keys) {
        updatedAttachedFilesMap[label] = [];
      }

      // Upload files one by one
      for (var label in attachedFilesMap.keys) {
        if (!attachedFilesMap.containsKey(label) ||
            attachedFilesMap[label] == null) {
          continue; // Skip if no files for this label
        }

        for (int i = 0; i < attachedFilesMap[label]!.length; i++) {
          final fileData = attachedFilesMap[label]![i];

          // Validate file data
          if (fileData == null ||
              !fileData.containsKey('path') ||
              fileData['path'] == null) {
            print('Invalid file data: $fileData');
            continue;
          }

          // If this file already has a download URL, just add it to the updated map
          if (fileData['downloadUrl'] != null &&
              fileData['downloadUrl'].toString().isNotEmpty) {
            updatedAttachedFilesMap[label]!
                .add(Map<String, dynamic>.from(fileData));
            continue;
          }

          // Handle new file upload
          if (fileData['path'] != null) {
            try {
              final filePath = fileData['path'];
              final file = File(filePath);

              if (!await file.exists()) {
                continue;
              }

              final fileSize = await file.length();
              if (fileSize == 0) {
                continue;
              }

              currentFileUploadIndex++;
              setState(() {
                uploadProgressMessage =
                    'Uploading files ($currentFileUploadIndex/$totalFilesToUpload)';
              });

              final fileName = path.basename(file.path);
              final uniqueFileName =
                  '${DateTime.now().millisecondsSinceEpoch}_$fileName';

              final storageRef = FirebaseStorage.instance.ref().child(
                  'users/${user.uid}/applications/${widget.application['id']}/$label/$uniqueFileName');

              // Upload file with retry logic and timeout
              try {
                final metadata = SettableMetadata(
                    contentType: _getContentType(fileName),
                    customMetadata: {'picked-file-path': file.path});

                final uploadTask = storageRef.putFile(file, metadata);
                final completer = Completer<TaskSnapshot>();

                uploadTask.then(completer.complete).catchError((error) {
                  print('Upload task error: $error');
                  completer.completeError(error);
                });

                final snapshot = await completer.future
                    .timeout(Duration(minutes: 5), onTimeout: () {
                  print('Upload timed out after 5 minutes');
                  uploadTask.cancel();
                  throw TimeoutException('Upload timed out after 5 minutes');
                });

                final downloadUrl = await snapshot.ref.getDownloadURL();

                // Add the file to the updated map with the download URL
                updatedAttachedFilesMap[label]!.add({
                  'name': fileData['name'],
                  'path': fileData['path'], // Keep local path for cache
                  'downloadUrl': downloadUrl, // Store download URL
                });
              } catch (uploadError) {
                print('Error uploading file: $uploadError');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Error uploading ${fileData['name']}: ${uploadError.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
                continue;
              }
            } catch (fileError) {
              print('Error processing file: $fileError');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Error processing file: ${fileData['name'] ?? 'unknown file'}'),
                  backgroundColor: Colors.red,
                ),
              );
              continue;
            }
          }
        }
      }

      setState(() {
        isUploadingFiles = false;
        uploadProgressMessage = 'Saving form data...';

        // Update the attachedFilesMap with the updated data
        attachedFilesMap = updatedAttachedFilesMap;
      });

      // Update originalAttachedFilesMap
      originalAttachedFilesMap = <String, List<Map<String, dynamic>>>{};
      for (var label in attachedFilesMap.keys) {
        originalAttachedFilesMap[label] = List<Map<String, dynamic>>.from(
            attachedFilesMap[label]!
                .map((item) => Map<String, dynamic>.from(item)));
      }

      // Get the original form fields
      final forms = widget.application['details']['forms'] ?? [];

      // Create the new formFields structure with answers
      final formFields = [];

      for (var form in forms) {
        var formField = Map<String, dynamic>.from(form);

        // Add answers based on form type
        switch (form['type']) {
          case 'short_answer':
          case 'paragraph':
            formField['answer'] = textControllers[form['label']]?.text ?? '';
            break;

          case 'multiple_choice':
            formField['selectedOption'] = selectedOption;
            break;

          case 'checkbox':
            // For checkbox, create a list of selected options
            if (form['options'] != null) {
              final List<String> selectedOptions = [];
              for (var option in form['options']) {
                if (checkboxValues[option] == true) {
                  selectedOptions.add(option);
                }
              }
              formField['selectedOptions'] = selectedOptions;
            }
            break;

          case 'date':
            formField['selectedDate'] =
                selectedDates[form['label']]?.toIso8601String();
            break;

          case 'attachment':
            // For attachments, add the file information
            if (attachedFilesMap.containsKey(form['label'])) {
              formField['files'] = attachedFilesMap[form['label']]!
                  .map((file) => {
                        'name': file['name'],
                        'downloadUrl': file['downloadUrl']
                      })
                  .toList();
            } else {
              formField['files'] = [];
            }
            break;
        }

        formFields.add(formField);
      }

      // Save the formFields to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('users-application')
          .doc(widget.application['id'])
          .update({'formFields': formFields});

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
        final formFields = doc.data()!['formFields'] ?? [];

        // Process each form field and populate the UI
        for (var field in formFields) {
          final String fieldType = field['type'] ?? '';
          final String fieldLabel = field['label'] ?? '';

          switch (fieldType) {
            case 'short_answer':
            case 'paragraph':
              if (textControllers.containsKey(fieldLabel)) {
                textControllers[fieldLabel]!.text = field['answer'] ?? '';
              }
              break;

            case 'multiple_choice':
              setState(() {
                selectedOption = field['selectedOption'];
              });
              break;

            case 'checkbox':
              if (field['options'] != null &&
                  field['selectedOptions'] != null) {
                for (var option in field['options']) {
                  checkboxValues[option] =
                      field['selectedOptions'].contains(option);
                }
              }
              break;

            case 'date':
              if (field['selectedDate'] != null) {
                setState(() {
                  selectedDates[fieldLabel] =
                      DateTime.parse(field['selectedDate']);
                });
              }
              break;

            case 'attachment':
              if (field['files'] != null) {
                final List<dynamic> files = field['files'];
                attachedFilesMap[fieldLabel] = [];
                originalAttachedFilesMap[fieldLabel] = [];

                for (var file in files) {
                  final fileMap = {
                    'name': file['name'],
                    'downloadUrl': file['downloadUrl'],
                    'path': null // Local path will be populated when downloaded
                  };
                  attachedFilesMap[fieldLabel]!.add(fileMap);
                  originalAttachedFilesMap[fieldLabel]!
                      .add(Map<String, dynamic>.from(fileMap));
                }
              }
              break;
          }
        }
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

  // Method to remove a file
  void removeFile(String label, Map<String, dynamic> fileData) {
    setState(() {
      // Add the file to the list of files to be deleted if it has a download URL
      if (fileData.containsKey('downloadUrl') &&
          fileData['downloadUrl'] != null &&
          fileData['downloadUrl'].toString().isNotEmpty) {
        filesToDelete.add(fileData['downloadUrl']);
      }

      // Remove from UI list
      attachedFilesMap[label]!.remove(fileData);
    });
  }

  // New method to delete application form data and associated files
  Future<void> deleteApplication() async {
    // Show confirmation dialog
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Cancel Application'),
              content: Text(
                  'Are you sure you want to cancel this application? All data and uploaded files will be permanently deleted.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('No, Keep It'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Yes, Cancel Application',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmDelete) return;

    setState(() {
      isSaving = true;
      uploadProgressMessage = 'Deleting application...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You must be signed in to delete an application'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Reference to the application document
      final applicationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('users-application')
          .doc(widget.application['id']);

      // Get the current form data to find all attached files
      final applicationDoc = await applicationRef.get();
      final formData = applicationDoc.data()?['form_data'];

      // Delete all files from Firebase Storage if they exist
      if (formData != null && formData['attachments'] != null) {
        final attachments = formData['attachments'] as Map<String, dynamic>;

        for (var fieldKey in attachments.keys) {
          final fieldFiles = attachments[fieldKey] as List<dynamic>;
          for (var file in fieldFiles) {
            if (file['downloadUrl'] != null &&
                file['downloadUrl'].toString().isNotEmpty) {
              try {
                // Delete file from Firebase Storage
                final ref =
                    FirebaseStorage.instance.refFromURL(file['downloadUrl']);
                await ref.delete();
                print('Deleted file: ${file['name']} from Firebase Storage');
              } catch (e) {
                print('Error deleting file from storage: $e');
                // Continue with other deletions even if this one fails
              }
            }
          }
        }
      }

      // Delete the application document from Firestore
      await applicationRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to previous screen with true to trigger refresh
      Navigator.of(context).pop(true);
    } catch (error) {
      print('Error deleting application: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling application: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  // Add a new method to submit application
  Future<void> submitApplication() async {
    // Show confirmation dialog
    final bool confirmSubmit = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Submit Application'),
              content: Text(
                'Are you sure you want to submit this application? Once submitted, it will be sent to the organization for review.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Submit',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmSubmit) return;

    // Save form data first
    setState(() {
      isSaving = true;
      uploadProgressMessage = 'Submitting application...';
    });

    try {
      // Save form data by calling the existing saveFormData method
      await saveFormData();

      // Update application status to Pending
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not signed in');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('users-application')
          .doc(widget.application['id'])
          .update({'status': 'Pending'});

      // Navigate to pending page with replacement and also set result for any parent pages
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ApplicationPendingPage(
            application: {
              ...widget.application,
              'status': 'Pending',
            },
          ),
          settings: RouteSettings(name: 'pending_${widget.application['id']}'),
        ),
      );

      // Also pop with true result to trigger refresh if this is popped directly
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      print('Error submitting application: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting application: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isSaving = false;
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
              // Add delete button
              if (!isSaving)
                IconButton(
                  onPressed: deleteApplication,
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Cancel Application',
                ),
              // Save button or progress indicator
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
                  // Header Section - Make it tappable
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplicationDetailsPage(
                              application: widget.application,
                              hideApplyButton: true, // Don't show Apply button
                            ),
                          ),
                        );
                      },
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
                                  // Replace CircleAvatar with a container showing the logo URL
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: widget.application['logoUrl'] !=
                                                null &&
                                            widget.application['logoUrl']
                                                .toString()
                                                .isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Image.network(
                                              widget.application['logoUrl'],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.business,
                                                  color: Colors.grey[800],
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.business,
                                            color: Colors.grey[800],
                                          ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        widget.application[
                                                'organizationName'] ??
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                              text: widget.application[
                                                      'deadline'] ??
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
                                                removeFile(
                                                    form['label'], fileData);
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
          onPressed: isSaving ? null : submitApplication,
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

  // Add the missing darkenColor function
  Color darkenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final darkColor =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return darkColor.toColor();
  }
}
