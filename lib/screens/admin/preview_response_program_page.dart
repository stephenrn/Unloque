import 'package:flutter/material.dart';
import 'package:unloque/models/organization_response_section.dart';
import 'package:unloque/widgets/organization_response_sections.dart';

class PreviewResponseProgramPage extends StatelessWidget {
  final List<ResponseSection> responseSections;
  final Map<String, dynamic> application; // Add this parameter

  const PreviewResponseProgramPage({
    Key? key,
    required this.responseSections,
    required this.application, // Add this parameter
  }) : super(key: key);

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
                          children: [
                            OrganizationResponseSections(
                              sections: responseSections,
                              underlineAllAttachments: true,
                            ),
                          ],
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

  
}
