import 'package:flutter/material.dart';
import 'package:unloque/pages/application_details_page.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<String, List<Map<String, String>>> attachedFilesMap =
      {}; // For attachments
  Map<String, TextEditingController> textControllers =
      {}; // For short answer and paragraph inputs

  @override
  void initState() {
    super.initState();
    loadFormData(); // Load saved form data when the page is initialized
    final forms = widget.application['details']['forms'] ?? [];
    for (var form in forms) {
      if (form['type'] == 'checkbox') {
        for (var option in form['options']) {
          checkboxValues[option] = false; // Default to unchecked
        }
      } else if (form['type'] == 'date') {
      } else if (form['type'] == 'date') {
        selectedDates[form['label']] = null; // Initialize dates as null
      } else if (form['type'] == 'attachment') {
        attachedFilesMap[form['label']] =
            attachedFilesMap[form['label']] ?? []; // Ensure non-null list
      } else if (form['type'] == 'short_answer' ||
          form['type'] == 'paragraph') {
        textControllers[form['label']] =
            TextEditingController(); // Initialize text controllers
      }
    }
  }

  @override
  void dispose() {
    // Dispose all text controllers to avoid memory leaks
    for (var controller in textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> saveFormData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle case where user is not signed in
      return;
    }

    final formData = {
      'short_answers': textControllers.map((key, controller) =>
          MapEntry(key, controller.text)), // Store short answer responses
      'paragraphs': textControllers.map((key, controller) =>
          MapEntry(key, controller.text)), // Store paragraph responses
      'multiple_choice': selectedOption, // Store selected option
      'checkboxes': checkboxValues, // Store checkbox selections
      'dates': selectedDates.map((key, value) =>
          MapEntry(key, value?.toIso8601String())), // Store selected dates
      'attachments': attachedFilesMap, // Store attached files
    };

    // Update the existing document in the 'users-application' collection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('users-application')
        .doc(widget
            .application['id']) // Use the application ID as the document ID
        .update({'form_data': formData}); // Update the 'form_data' field

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Form data saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> loadFormData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('users-application')
        .doc(widget
            .application['id']) // Use the application ID as the document ID
        .get();

    if (doc.exists && doc.data() != null) {
      final formData = doc.data()!['form_data'] ?? {};
      setState(() {
        selectedOption = formData['multiple_choice'];
        checkboxValues = Map<String, bool>.from(formData['checkboxes'] ?? {});
        selectedDates = Map<String, DateTime?>.from(
          (formData['dates'] ?? {}).map((key, value) => MapEntry(
                key,
                value != null
                    ? DateTime.parse(value)
                    : null, // Handle null values
              )),
        );
        attachedFilesMap = (formData['attachments'] ?? {})
            .map<String, List<Map<String, String>>>(
          (key, value) => MapEntry(
            key as String, // Explicitly cast the key to String
            (value as List<dynamic>)
                .map((item) => Map<String, String>.from(item))
                .toList(), // Safely cast each item to Map<String, String>
          ),
        );
        textControllers.forEach((key, controller) {
          controller.text =
              formData['short_answers']?[key] ?? ''; // Load short answers
        });
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
                    'Application Form',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    saveFormData, // Save form data when the button is pressed
                icon: Icon(Icons.save, color: Colors.grey[800]),
                tooltip: 'Save Form',
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
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
                        color: Colors.grey[800] ?? Colors.black, width: 0.5),
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
                                        text: widget.application['deadline'] ??
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
                        color: Colors.grey[800] ?? Colors.black, width: 0.5),
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
                                maxLines: form['type'] == 'paragraph' ? 5 : 1,
                                decoration: InputDecoration(
                                  hintText: form['placeholder'],
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ] else if (form['type'] == 'multiple_choice') ...[
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
                                return CheckboxListTile(
                                  value: checkboxValues[option],
                                  tristate: true,
                                  onChanged: (value) {
                                    setState(() {
                                      checkboxValues[option] = value ?? false;
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
                                  hintText: selectedDates[form['label']] == null
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
                                  FilePickerResult? result = await FilePicker
                                      .platform
                                      .pickFiles(allowMultiple: true);
                                  if (result != null) {
                                    final appDir =
                                        await getApplicationDocumentsDirectory();
                                    for (var file in result.files) {
                                      final filePath = file.path!;
                                      final fileName = file.name;

                                      if (filePath.startsWith('http')) {
                                        // Download file from Google Drive
                                        final response =
                                            await http.get(Uri.parse(filePath));
                                        final localFile =
                                            File('${appDir.path}/$fileName');
                                        await localFile
                                            .writeAsBytes(response.bodyBytes);
                                        setState(() {
                                          attachedFilesMap[form['label']]!.add({
                                            'name': fileName,
                                            'path': localFile.path,
                                          });
                                        });
                                      } else {
                                        // Copy local file
                                        final localFile = await File(filePath)
                                            .copy('${appDir.path}/$fileName');
                                        setState(() {
                                          attachedFilesMap[form['label']]!.add({
                                            'name': fileName,
                                            'path': localFile.path,
                                          });
                                        });
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: attachedFilesMap[form['label']]!
                                      .map((file) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              final filePath = file['path'];
                                              if (filePath != null) {
                                                await OpenFilex.open(filePath);
                                              } else {
                                                print('File path is null');
                                              }
                                            },
                                            child: Text(
                                              file['name']!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              attachedFilesMap[form['label']]!
                                                  .remove(file);
                                            });
                                          },
                                          icon: Icon(Icons.close,
                                              color: Colors.red),
                                          tooltip: 'Remove file',
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                            SizedBox(
                                height: 24), // Add spacing between questions
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
