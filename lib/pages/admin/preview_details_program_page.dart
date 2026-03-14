import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'dart:io';

class PreviewProgramDetailsPage extends StatefulWidget {
  final String organizationId;
  final String programId;
  // Accept detailSections to preview unsaved changes
  final List<Map<String, dynamic>>? detailSections;

  const PreviewProgramDetailsPage({
    Key? key,
    required this.organizationId,
    required this.programId,
    this.detailSections,
  }) : super(key: key);

  @override
  State<PreviewProgramDetailsPage> createState() =>
      _PreviewProgramDetailsPageState();
}

class _PreviewProgramDetailsPageState extends State<PreviewProgramDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _programData = {};
  Map<String, dynamic> _organizationData = {};
  List<Map<String, dynamic>> _detailSections = [];

  // Downloading states
  Map<String, bool> _downloadingFiles = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load program data from Firebase first
      final programDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('programs')
          .doc(widget.programId)
          .get();

      if (programDoc.exists) {
        _programData = programDoc.data() ?? {};

        // Always use detail sections from Firebase only
        if (_programData['detailSections'] != null) {
          _detailSections = List<Map<String, dynamic>>.from(
            _programData['detailSections'] as List<dynamic>,
          );
        } else {
          _detailSections = [];
        }
      } else {
        // If program doesn't exist in Firebase, show empty details
        _detailSections = [];
      }

      // Load organization data
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .get();

      if (orgDoc.exists) {
        _organizationData = orgDoc.data() ?? {};
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading data: $error';
      });
      print('Error loading preview data: $error');
    } finally {
      setState(() {
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

  Color darkenColor(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  @override
  Widget build(BuildContext context) {
    // Get color from program data or default to blue
    final Color programColor = _programData['color'] != null
        ? Color(_programData['color'])
        : Colors.blue[200]!;

    // Get program name
    final String programName = _programData['name'] ?? 'Program Preview';

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
              // Back button
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
              // Page title
              Expanded(
                child: Center(
                  child: Text(
                    'Program Preview',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              // Spacer to balance the layout
              SizedBox(width: 28),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Program header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: programColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey[800]!, width: 0.5),
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
                                      child: _organizationData['logoUrl'] !=
                                              null
                                          ? Image.network(
                                              _organizationData['logoUrl'],
                                              width: 40,
                                              height: 40,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.business,
                                                  color: Colors.grey[800],
                                                );
                                              },
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
                                            programName,
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
                                            _organizationData['name'] ??
                                                'Organization',
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
                                                text:
                                                    _programData['deadline'] ??
                                                        'No Deadline',
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
                                      _programData['category'] ?? 'No Category',
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

                      // Detail sections content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey[800]!, width: 0.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _detailSections.isEmpty
                                  ? [
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
                                      )
                                    ]
                                  : _renderDetailSections(),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
      // Emulate application button as non-functional to complete the preview look
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: null, // Disabled button
          style: ElevatedButton.styleFrom(
            backgroundColor: darkenColor(programColor),
            disabledBackgroundColor: darkenColor(programColor).withOpacity(0.7),
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
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _renderDetailSections() {
    List<Widget> sections = [];

    for (int i = 0; i < _detailSections.length; i++) {
      final section = _detailSections[i];
      final sectionType = section['type'] as String;
      final sectionLabel = section['label'] as String;

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
              padding: const EdgeInsets.only(
                  bottom: 2), // Reduced padding between items
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
                  child: Row(
                    children: [
                      if (isDownloading)
                        Container(
                          width: 24,
                          height: 24,
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          downloadUrl != null
                              ? Icons.insert_drive_file
                              : Icons.file_present_outlined,
                          size: 20,
                          color:
                              downloadUrl != null ? Colors.blue : Colors.grey,
                        ),
                      SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: downloadUrl != null
                              ? () =>
                                  _downloadAndOpenFile(downloadUrl, fileName)
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'This file has no download URL. Save the details first.'),
                                    ),
                                  );
                                },
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
                      if (downloadUrl != null)
                        Tooltip(
                          message: 'Download and Preview',
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
                    ],
                  ),
                ),
              );
            }
          }
        }
      }

      // Add divider except after the last section
      if (i < _detailSections.length - 1) {
        sections.add(SizedBox(height: 16));
        sections.add(Divider(color: Colors.grey[300]));
        sections.add(SizedBox(height: 16));
      }
    }

    return sections;
  }
}
