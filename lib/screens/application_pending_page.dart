import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unloque/screens/admin/organization_response_builder.dart';
import 'package:unloque/screens/application_details_page.dart';
import 'package:unloque/models/application_form_submission_field.dart';
import 'package:unloque/models/program_form_field.dart';
import 'package:unloque/services/applications/application_pending_service.dart';
import 'package:unloque/services/auth/auth_session_service.dart';

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

      if (!await localFile.exists()) {
        final response = await http.get(Uri.parse(downloadUrl));
        if (response.statusCode != 200) {
          throw Exception('Download failed (${response.statusCode})');
        }
        await localFile.writeAsBytes(response.bodyBytes);
      }

      await OpenFilex.open(localPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          processingFiles[fileName] = false;
        });
      }
    }
  }

  bool get isOrgAdminView {
    // Heuristic: if application has 'userId' field, it's opened from ApplicationManagerPage
    return widget.application.containsKey('userId');
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchHeaderDataAndForm(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading application data'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Application data not found'));
          }

          final header = snapshot.data!;
          final formDoc = header['formDoc'] as DocumentSnapshot?;
          final programName = header['programName'] ?? 'Program';
          final orgName = header['organizationName'] ?? 'Unknown Organization';
          final logoUrl = header['logoUrl'] ?? '';
          final deadline = header['deadline'] ?? '';
          final category = header['category'] ?? '';

          // Get the data, ensuring proper type casting
          Map<String, dynamic> data = {};
          try {
            data = formDoc?.data() as Map<String, dynamic>? ?? {};
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
                                  child: logoUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(
                                            logoUrl,
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
                                        programName.toString().isNotEmpty
                                            ? programName
                                            : 'Program',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        orgName.toString().isNotEmpty
                                            ? orgName
                                            : 'Unknown Organization',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        softWrap: true,
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
                                            text: 'Due: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          TextSpan(
                                            text: deadline.isNotEmpty
                                                ? deadline
                                                : 'No Deadline',
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
                                  category.isNotEmpty
                                      ? category
                                      : 'Unknown Category',
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
      // Add footer button for org admin
      bottomNavigationBar: isOrgAdminView
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: Icon(Icons.reply),
                label: Text('Create Response'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrganizationResponseBuilderPage(
                        application: widget.application,
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Future<Map<String, dynamic>> _fetchHeaderDataAndForm() async {
    final uid = AuthSessionService.currentUid();
    return ApplicationPendingService.fetchHeaderDataAndForm(
      application: widget.application,
      uid: uid,
    );
  }

  Widget _buildSubmittedFormContent(
      Map<String, dynamic> data, BuildContext context) {
    List<Widget> formItems = [];

    final rawFormFields = data['formFields'];
    if (rawFormFields == null) {
      return Center(child: Text('No form data submitted'));
    }

    final submittedFields =
      ApplicationSubmittedFormField.listFromDynamic(rawFormFields);

    if (submittedFields.isEmpty) {
      return Center(child: Text('No form data submitted'));
    }

    for (final field in submittedFields) {
      switch (field.type) {
        case ProgramFormFieldType.shortAnswer:
        case ProgramFormFieldType.paragraph:
          formItems.add(_buildFormItem(field.label, field.answer ?? ''));
          break;

        case ProgramFormFieldType.multipleChoice:
          final selectedOption = field.selectedOption;
          if (selectedOption != null && selectedOption.isNotEmpty) {
            formItems.add(_buildFormItem(field.label, selectedOption));
          }
          break;

        case ProgramFormFieldType.checkbox:
          if (field.selectedOptions.isNotEmpty) {
            formItems.add(
              _buildFormItem(field.label, field.selectedOptions.join(', ')),
            );
          }
          break;

        case ProgramFormFieldType.date:
          if (field.selectedDate != null) {
            final date =
                field.selectedDate!.toString().split(' ')[0];
            formItems.add(_buildFormItem(field.label, date));
          }
          break;

        case ProgramFormFieldType.attachment:
          if (field.files.isNotEmpty) {
            formItems.add(_buildAttachmentItem(field.label, field.files));
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
  Widget _buildAttachmentItem(
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
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: files.map<Widget>((fileData) {
                final fileName = fileData.name.isNotEmpty
                    ? fileData.name
                    : 'Unnamed File';
                final downloadUrl = fileData.downloadUrl;
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
                          onTap: downloadUrl.isNotEmpty
                              ? () => downloadAndOpenFile(fileName, downloadUrl)
                              : null,
                          child: Text(
                            fileName,
                            style: TextStyle(
                              fontSize: 14,
                              color: downloadUrl.isNotEmpty
                                  ? Colors.blue
                                  : Colors.grey,
                              decoration: downloadUrl.isNotEmpty
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
