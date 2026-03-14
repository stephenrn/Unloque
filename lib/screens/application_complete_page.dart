import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // <-- Add this import for consolidateHttpClientResponseBytes

class ApplicationCompletePage extends StatefulWidget {
  final Map<String, dynamic> application;

  const ApplicationCompletePage({super.key, required this.application});

  @override
  State<ApplicationCompletePage> createState() =>
      _ApplicationCompletePageState();
}

class _ApplicationCompletePageState extends State<ApplicationCompletePage> {
  Map<String, bool> downloadingFiles = {};

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
                  onPressed: () => Navigator.pop(context, true),
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
                    'Application Review Result',
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
        future: _fetchHeaderAndResponse(),
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
          final programName = header['programName'] ?? 'Program';
          final orgName = header['organizationName'] ?? 'Unknown Organization';
          final logoUrl = header['logoUrl'] ?? '';
          final deadline = header['deadline'] ?? '';
          final category = header['category'] ?? '';
          final responseSections =
              header['responseSections'] as List<Map<String, dynamic>>?;
          // formDoc is included in the header for other use-cases; not needed here.

          return SingleChildScrollView(
            child: Column(
              children: [
                // Status Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
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
                        Icons.info_outline,
                        size: 60,
                        color: Colors.grey[700],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Application Reviewed',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          'Your application has been reviewed by the organization. Please see the response below for the result and any feedback.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Application Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: logoUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: 20),

                // Organization Response Section
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
                      child:
                          responseSections == null || responseSections.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      'No response from the organization yet.',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              : _buildResponseSections(responseSections),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Add a neutral note at the bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "If your application was not successful, please don't be discouraged. You may review the feedback above and apply again in the future or to other programs.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchHeaderAndResponse() async {
    print("Fetching data for application: ${widget.application['id']}");
    
    final programId = widget.application['programId'] ?? 
                      widget.application['id'];
    final organizationId = widget.application['organizationId'] ?? 
                          widget.application['orgId'];
    
    print("Using programId: $programId, organizationId: $organizationId");

    String programName = widget.application['programName'] ?? '';
    String orgName = widget.application['organizationName'] ?? '';
    String logoUrl = widget.application['logoUrl'] ?? '';
    String deadline = widget.application['deadline'] ?? '';
    String category = widget.application['category'] ?? '';
    List<Map<String, dynamic>> responseSections = [];

    // Fetch program info if we have organizationId and programId
    if (organizationId != null && programId != null) {
      try {
        final programDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .collection('programs')
            .doc(programId)
            .get();
            
        if (programDoc.exists) {
          final data = programDoc.data() ?? {};
          if (programName.isEmpty) programName = (data['name'] ?? '').toString();
          if (deadline.isEmpty) deadline = (data['deadline'] ?? '').toString();
          if (category.isEmpty) category = (data['category'] ?? '').toString();
        } else {
          print("Program document does not exist for ID: $programId");
        }

        // Fetch organization info
        final orgDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .get();
            
        if (orgDoc.exists) {
          final data = orgDoc.data() ?? {};
          if (orgName.isEmpty) orgName = (data['name'] ?? '').toString();
          if (logoUrl.isEmpty) logoUrl = (data['logoUrl'] ?? '').toString();
        } else {
          print("Organization document does not exist for ID: $organizationId");
        }
      } catch (e) {
        print("Error fetching program/organization info: $e");
      }
    } else {
      print("Missing programId or organizationId");
    }

    // Fallback to application object if Firestore values are empty
    if (programName.isEmpty)
      programName = widget.application['programName'] ?? '';
    if (orgName.isEmpty) 
      orgName = widget.application['organizationName'] ?? '';
    if (logoUrl.isEmpty) 
      logoUrl = widget.application['logoUrl'] ?? '';
    if (deadline.isEmpty) 
      deadline = widget.application['deadline'] ?? '';
    if (category.isEmpty) 
      category = widget.application['category'] ?? '';

    // Fetch the user's application form document
    final user = FirebaseAuth.instance.currentUser;
    DocumentSnapshot? formDoc;
    final appId = widget.application['id'] ?? programId;
    if (user != null && appId != null) {
      formDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('users-application')
          .doc(appId)
          .get();

      // Get organization response from the application document
      final data = formDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        print("Application data found: ${data.keys}");
        if (data['organizationResponse'] != null) {
          final orgResponse = data['organizationResponse'];
          print("Organization response found: $orgResponse");
          if (orgResponse is Map && orgResponse['responseSections'] is List) {
            responseSections =
                List<Map<String, dynamic>>.from(orgResponse['responseSections']);
            print("Response sections count: ${responseSections.length}");
          }
        } else {
          print("No organization response found in application data");
        }
      }
    } else {
      print("Unable to fetch application document - user: $user, appId: $appId");
    }

    return {
      'programName': programName,
      'organizationName': orgName,
      'logoUrl': logoUrl,
      'deadline': deadline,
      'category': category,
      'responseSections': responseSections,
      'formDoc': formDoc,
    };
  }

  Widget _buildResponseSections(List<Map<String, dynamic>> sections) {
    List<Widget> widgets = [];
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final type = section['type'] ?? '';
      final label = section['label'] ?? '';

      widgets.add(
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      );
      widgets.add(SizedBox(height: 8));

      if (type == 'paragraph') {
        widgets.add(
          Text(
            section['content'] ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        );
      } else if (type == 'list') {
        final items = List<String>.from(section['items'] ?? []);
        for (var item in items) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 4, right: 8),
                    child: Icon(Icons.circle, size: 6, color: Colors.blue),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else if (type == 'attachment') {
        final files = List<Map<String, dynamic>>.from(section['files'] ?? []);
        if (files.isEmpty) {
          widgets.add(
            Text(
              'No attachments available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        } else {
          for (var fileData in files) {
            final fileName = fileData['name'] ?? 'Unnamed file';
            final downloadUrl = fileData['downloadUrl'];
            final isDownloading = downloadingFiles[fileName] ?? false;

            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (isDownloading)
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
                            ? () => _downloadAndOpenFile(downloadUrl, fileName)
                            : null,
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }

      if (i < sections.length - 1) {
        widgets.add(SizedBox(height: 16));
        widgets.add(Divider(color: Colors.grey[300]));
        widgets.add(SizedBox(height: 16));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Future<void> _downloadAndOpenFile(String downloadUrl, String fileName) async {
    setState(() {
      downloadingFiles[fileName] = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/$fileName';
      final file = File(localPath);

      if (!await file.exists()) {
        final response = await HttpClient().getUrl(Uri.parse(downloadUrl));
        final httpResponse = await response.close();
        // Use the correct function from flutter/foundation.dart
        final bytes = await consolidateHttpClientResponseBytes(httpResponse);
        await file.writeAsBytes(bytes);
      }

      await OpenFilex.open(localPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    } finally {
      setState(() {
        downloadingFiles[fileName] = false;
      });
    }
  }
}
