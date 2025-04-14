import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unloque/pages/application_details_page.dart'; // Add this import

class ApplicationPendingPage extends StatefulWidget {
  final Map<String, dynamic> application;

  const ApplicationPendingPage({super.key, required this.application});

  @override
  _ApplicationPendingPageState createState() => _ApplicationPendingPageState();
}

class _ApplicationPendingPageState extends State<ApplicationPendingPage> {
  // Track files being opened/downloaded
  Map<String, bool> processingFiles = {};

  // Method to download and open a file
  Future<void> downloadAndOpenFile(String fileName, String downloadUrl) async {
    if (downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No download URL available for this file')),
      );
      return;
    }

    setState(() {
      processingFiles[fileName] = true;
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
        processingFiles[fileName] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () => Navigator.pop(
                      context, true), // Return true to trigger refresh
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
                    'Application Status',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _loadFormData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading application data'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Application data not found'));
          }

          // Get the data, ensuring proper type casting
          Map<String, dynamic> data = {};
          try {
            data = snapshot.data!.data() as Map<String, dynamic>;
          } catch (e) {
            print('Error casting document data: $e');
            return Center(child: Text('Error parsing application data'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Status Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_top,
                        size: 60,
                        color: Colors.amber[800],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Application Under Review',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Your application is being reviewed by the organization',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Application Header Section
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
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Section: Title, Logo, and Subtitle
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Replace CircleAvatar with Container showing the logo URL
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
                                Expanded(
                                  child: Column(
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
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
                                            text: 'Submitted: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          TextSpan(
                                            text: DateTime.now()
                                                .toString()
                                                .split(' ')[0],
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
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
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
                SizedBox(height: 20),

                // Submitted Information Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[800] ?? Colors.black,
                        width: 0.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSubmittedFormContent(data, context),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<DocumentSnapshot> _loadFormData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    return await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('users-application')
        .doc(widget.application['id'])
        .get();
  }

  Widget _buildSubmittedFormContent(
      Map<String, dynamic> data, BuildContext context) {
    List<Widget> formItems = [];

    // Get formFields from the new data structure with proper type casting
    final formFields = data['formFields'];
    if (formFields == null) {
      return Center(child: Text('No form data submitted'));
    }

    List<Map<String, dynamic>> typedFormFields = [];

    // Convert the dynamic list to properly typed list
    if (formFields is List) {
      for (var field in formFields) {
        if (field is Map) {
          // Convert each field to a properly typed Map<String, dynamic>
          typedFormFields.add(Map<String, dynamic>.from(field));
        }
      }
    }

    if (typedFormFields.isEmpty) {
      return Center(child: Text('No form data submitted'));
    }

    // Process each form field with proper typing
    for (var field in typedFormFields) {
      final String fieldType = field['type'] ?? '';
      final String fieldLabel = field['label'] ?? '';

      switch (fieldType) {
        case 'short_answer':
        case 'paragraph':
          final String answer = field['answer'] ?? '';
          formItems.add(_buildFormItem(fieldLabel, answer));
          break;

        case 'multiple_choice':
          final selectedOption = field['selectedOption'];
          if (selectedOption != null && selectedOption.toString().isNotEmpty) {
            formItems
                .add(_buildFormItem(fieldLabel, selectedOption.toString()));
          }
          break;

        case 'checkbox':
          final selectedOptions = field['selectedOptions'];
          if (selectedOptions is List && selectedOptions.isNotEmpty) {
            formItems
                .add(_buildFormItem(fieldLabel, selectedOptions.join(', ')));
          }
          break;

        case 'date':
          final selectedDate = field['selectedDate'];
          if (selectedDate != null) {
            final date = DateTime.parse(selectedDate.toString())
                .toString()
                .split(' ')[0];
            formItems.add(_buildFormItem(fieldLabel, date));
          }
          break;

        case 'attachment':
          final files = field['files'];
          if (files is List && files.isNotEmpty) {
            // Convert to properly typed list
            List<Map<String, dynamic>> typedFiles = [];
            for (var file in files) {
              if (file is Map) {
                typedFiles.add(Map<String, dynamic>.from(file));
              }
            }
            if (typedFiles.isNotEmpty) {
              formItems.add(_buildAttachmentItem(fieldLabel, typedFiles));
            }
          }
          break;
      }
    }

    if (formItems.isEmpty) {
      return Center(child: Text('No form data submitted'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submitted Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        ...formItems,
        SizedBox(height: 16),
        Center(
          child: Text(
            'You will be notified when the review is complete',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Add the missing _buildFormItem method
  Widget _buildFormItem(String label, String value) {
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
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build attachment item to handle the new structure
  Widget _buildAttachmentItem(String label, List<Map<String, dynamic>> files) {
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
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: files.map<Widget>((fileData) {
                final fileName = fileData['name'] ?? 'Unnamed File';
                final downloadUrl = fileData['downloadUrl'] as String?;
                final isProcessing = processingFiles[fileName] ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (isProcessing)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.insert_drive_file,
                            size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: downloadUrl != null &&
                                  downloadUrl.toString().isNotEmpty
                              ? () => downloadAndOpenFile(fileName, downloadUrl)
                              : null,
                          child: Text(
                            fileName,
                            style: TextStyle(
                              fontSize: 14,
                              color: downloadUrl != null
                                  ? Colors.blue
                                  : Colors.grey,
                              decoration: downloadUrl != null
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
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
}
