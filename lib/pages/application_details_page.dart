import 'package:flutter/material.dart';
import 'package:unloque/pages/application_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unloque/data/available_applications_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'dart:io';

Color darkenColor(Color color, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(color);
  final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return darkened.toColor();
}

class ApplicationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> application;
  final bool hideApplyButton; // Parameter to control button visibility

  const ApplicationDetailsPage({
    super.key,
    required this.application,
    this.hideApplyButton = false,
  });

  @override
  State<ApplicationDetailsPage> createState() => _ApplicationDetailsPageState();
}

class _ApplicationDetailsPageState extends State<ApplicationDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _applicationDetails = {};
  bool _isProgramOpen = false;

  // Downloading states
  Map<String, bool> _downloadingFiles = {};

  @override
  void initState() {
    super.initState();
    _loadApplicationDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page dependencies change (e.g., when returning to this page)
    _loadApplicationDetails();
  }

  Future<void> _loadApplicationDetails() async {
    // Only set loading state if we're not already loaded
    if (_applicationDetails.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Fetch fresh data from Firebase
      final fullDetails = await AvailableApplicationsData.getApplicationById(
          widget.application['id']);

      // Debugging: Log the fetched data
      print('Fetched Application Details: $fullDetails');

      if (fullDetails.isNotEmpty) {
        setState(() {
          _applicationDetails = fullDetails;
          _isProgramOpen = fullDetails['programStatus'] == 'Open';
          _isLoading = false;
        });
      } else {
        // Fallback to widget data if no details are found
        setState(() {
          _applicationDetails = widget.application;
          _isProgramOpen = widget.application['programStatus'] == 'Open';
          _isLoading = false;
        });
      }

      // Debugging: Log the entire application details object
      print('Application Details Object: $_applicationDetails');
      print('DetailSections: ${_applicationDetails['detailSections']}');
    } catch (e) {
      print('Error loading application details: $e');
      // On error, fall back to application data from widget
      setState(() {
        _applicationDetails = widget.application;
        _isLoading = false;
      });
    }
  }

  // Enhanced function to download and open files from Firebase Storage
  Future<void> _downloadAndOpenFile(String downloadUrl, String fileName) async {
    if (_downloadingFiles[fileName] == true) {
      return; // Already downloading
    }

    setState(() {
      _downloadingFiles[fileName] = true;
    });

    try {
      // Get temporary directory to store downloaded file
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/$fileName';
      final file = File(localPath);

      // Check if file exists locally and isn't empty before downloading again
      bool needsDownload = true;
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          needsDownload = false;
          print('Using cached file: $localPath');
        }
      }

      // Download file if needed
      if (needsDownload) {
        // Show download indicator with SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading $fileName...')),
        );

        try {
          final response = await http.get(Uri.parse(downloadUrl));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
            print('File downloaded successfully to: $localPath');
          } else {
            throw Exception('Failed to download file: ${response.statusCode}');
          }
        } catch (e) {
          print('Error downloading file: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error downloading file: ${e.toString()}')),
          );
          rethrow;
        }
      } else {
        // Indicate using cached version
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening cached copy of $fileName')),
        );
      }

      // Open the file
      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done) {
        throw Exception("Could not open file: ${result.message}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling file: $e')),
      );
    } finally {
      setState(() {
        _downloadingFiles[fileName] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final details = _applicationDetails['details'];
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100], // White background
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
                  color: Colors.grey[800], // Grey circle background
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: Transform.rotate(
                    angle: 4.71239, // Rotate arrow to point left
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white, // White arrow
                      size: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Application Details',
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Program header with status indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: _applicationDetails['categoryColor'],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Section with name and organization
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
                              child: _applicationDetails['logoUrl'] != null &&
                                      _applicationDetails['logoUrl']
                                          .toString()
                                          .isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        _applicationDetails['logoUrl'],
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
                                    _applicationDetails['programName'],
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
                                    _applicationDetails['organizationName'],
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

                      // Bottom Section: Due Date and Status
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
                                        text: _applicationDetails['deadline'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Status indicator
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _isProgramOpen
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isProgramOpen
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _isProgramOpen ? 'Open' : 'Closed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isProgramOpen
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _applicationDetails['category'],
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

              // Program details content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: 600, // Fixed width
                  constraints: BoxConstraints(
                    maxWidth: 600, // Ensure it doesn't exceed this width
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _renderDetailSections(details),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (widget.hideApplyButton || !_isProgramOpen)
          ? null // Hide button when specified or when program is closed
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please sign in to apply')),
                    );
                    return;
                  }

                  // Check if application already exists
                  final applicationDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('users-application')
                      .doc(_applicationDetails['id'])
                      .get();

                  if (applicationDoc.exists) {
                    // Show dialog if application already exists
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Application Already Exists'),
                          content: Text(
                              'You have already applied for this opportunity. You can view it in your applications list.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }

                  // If application doesn't exist, proceed with adding it
                  final applicationData = {
                    'id': _applicationDetails['id'],
                    'status': 'Ongoing',
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('users-application')
                      .doc(_applicationDetails['id'])
                      .set(applicationData);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ApplicationFormPage(application: _applicationDetails),
                    ),
                  ).then((result) {
                    if (result == true) {
                      Navigator.pop(context, true); // Propagate refresh signal
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      darkenColor(_applicationDetails['categoryColor']),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Apply Now',
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

  // Updated method to strictly render detailSections from Firebase
  List<Widget> _renderDetailSections(Map<String, dynamic> details) {
    List<Widget> sections = [];
    List<dynamic>? detailSections;

    // Fetch detailSections directly from Firebase data or fallback to details['detailSections']
    if (_applicationDetails['detailSections'] != null &&
        _applicationDetails['detailSections'] is List) {
      detailSections = _applicationDetails['detailSections'] as List<dynamic>;
    } else if (details != null &&
        details['detailSections'] != null &&
        details['detailSections'] is List) {
      detailSections = details['detailSections'] as List<dynamic>;
    }

    // Debugging: Log the detailSections to verify data
    print('DetailSections (render): $detailSections');

    // If detailSections are found, render them
    if (detailSections != null && detailSections.isNotEmpty) {
      for (int i = 0; i < detailSections.length; i++) {
        final section = detailSections[i];
        if (section == null) continue;

        final sectionType = section['type'] as String?;
        final sectionLabel = section['label'] as String?;

        if (sectionType == null || sectionLabel == null) continue;

        // Add section header
        sections.add(
          Text(
            sectionLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        );
        sections.add(SizedBox(height: 8));

        // Render content based on section type
        if (sectionType == 'paragraph') {
          sections.add(
            Text(
              section['content'] ?? 'No content available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          );
        } else if (sectionType == 'list') {
          final items = section['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            sections.add(
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
                        item.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else if (sectionType == 'attachment') {
          final files = section['files'] as List<dynamic>? ?? [];
          if (files.isEmpty) {
            sections.add(
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
              if (fileData is Map<String, dynamic>) {
                final fileName = fileData['name'] ?? 'Unnamed file';
                final downloadUrl = fileData['downloadUrl'];
                final isDownloading = _downloadingFiles[fileName] ?? false;

                sections.add(
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    margin: EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12),
                        if (isDownloading)
                          Container(
                            width: 24,
                            height: 24,
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.insert_drive_file,
                            size: 20,
                            color: Colors.blue,
                          ),
                        SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: downloadUrl != null
                                ? () =>
                                    _downloadAndOpenFile(downloadUrl, fileName)
                                : null,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: downloadUrl != null
                                      ? Colors.blue
                                      : Colors.grey,
                                  decoration: downloadUrl != null
                                      ? TextDecoration.underline
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (downloadUrl != null)
                          Tooltip(
                            message: 'View File',
                            child: IconButton(
                              icon: Icon(Icons.visibility, size: 18),
                              onPressed: () =>
                                  _downloadAndOpenFile(downloadUrl, fileName),
                              constraints:
                                  BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                              color: Colors.blue,
                            ),
                          ),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                );
              }
            }
          }
        }

        // Add divider except after the last section
        if (i < detailSections.length - 1) {
          sections.add(SizedBox(height: 16));
          sections.add(Divider(color: Colors.grey[300]));
          sections.add(SizedBox(height: 16));
        }
      }
    } else {
      // If no detailSections are found, show a message
      sections.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'No details available for this program yet.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return sections;
  }

  // Helper method to determine the appropriate icon based on file extension
  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}
