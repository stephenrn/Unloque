import 'package:flutter/material.dart';

class PreviewResponseProgramPage extends StatelessWidget {
  final List<Map<String, dynamic>> responseSections;
  const PreviewResponseProgramPage({Key? key, required this.responseSections})
      : super(key: key);

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
                    'Organization Response Preview',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user,
                          color: Colors.blue[700], size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'This is a preview of the response that will be sent to the applicant.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: responseSections.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No response sections defined yet.',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _renderSections(),
                        ),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _renderSections() {
    List<Widget> widgets = [];
    for (int i = 0; i < responseSections.length; i++) {
      final section = responseSections[i];
      final type = section['type'];
      final label = section['label'];
      widgets.add(
        Text(
          label,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
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
                  fontStyle: FontStyle.italic),
            ),
          );
        } else {
          for (var file in files) {
            final fileName = file['name'] ?? 'Unnamed file';
            widgets.add(
              Row(
                children: [
                  Icon(Icons.insert_drive_file, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }
      if (i < responseSections.length - 1) {
        widgets.add(SizedBox(height: 16));
        widgets.add(Divider(color: Colors.grey[300]));
        widgets.add(SizedBox(height: 16));
      }
    }
    return widgets;
  }
}
