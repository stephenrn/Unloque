import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // <-- Add this import for consolidateHttpClientResponseBytes
import 'package:unloque/services/applications/application_complete_service.dart';
import 'package:unloque/services/auth/auth_session_service.dart';
import 'package:unloque/models/organization_response_section.dart';
import 'package:unloque/widgets/organization_response_sections.dart';

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
              (header['responseSections'] as List<ResponseSection>?) ??
                const <ResponseSection>[];
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
                          responseSections.isEmpty
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
    final uid = AuthSessionService.currentUid();
    return ApplicationCompleteService.fetchHeaderAndResponse(
      application: widget.application,
      uid: uid,
    );
  }

  Widget _buildResponseSections(List<ResponseSection> sections) {
    return OrganizationResponseSections(
      sections: sections,
      downloadingFiles: downloadingFiles,
      onAttachmentTap: _downloadAndOpenFile,
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
