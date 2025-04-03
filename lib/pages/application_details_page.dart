import 'package:flutter/material.dart';
import 'package:unloque/pages/application_form_page.dart';

Color darkenColor(Color color, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(color);
  final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return darkened.toColor();
}

class ApplicationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> application;

  const ApplicationDetailsPage({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final details = application['details'];
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
                      color:
                          Colors.grey[800], // Adjusted text color for contrast
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
              // Combined Header and Due Date Section
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16), // Added side padding
                child: Container(
                  decoration: BoxDecoration(
                    color: application['categoryColor'],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.grey[800]!, width: 0.5), // Added border
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
                                application['organizationLogo'],
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  application['programName'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  application['organizationName'],
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
                            bottomLeft: Radius.circular(
                                15), // Match the parent container
                            bottomRight: Radius.circular(
                                15), // Match the parent container
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
                                        text: application['deadline'],
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
                              application['category'],
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
              // Scrollable content inside the rounded container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.grey[800]!, width: 0.5), // Thinner border
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description Section
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          details['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        Divider(color: Colors.grey[300]), // Grey line divider
                        SizedBox(height: 6),

                        // Requirements Section
                        Text(
                          'Requirements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        ...details['requirements'].map<Widget>((req) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading:
                                Icon(Icons.check_circle, color: Colors.blue),
                            title: Text(
                              req,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 16),
                        Divider(color: Colors.grey[300]), // Grey line divider
                        SizedBox(height: 6),

                        // Eligibility Section
                        Text(
                          'Eligibility',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        ...details['eligibility']['points']
                            .map<Widget>((point) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading:
                                Icon(Icons.check_circle, color: Colors.green),
                            title: Text(
                              point,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 8),
                        Text(
                          details['eligibility']['extra'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ApplicationFormPage(application: application),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                darkenColor(application['categoryColor']!), // Darken the color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24), // Make it rounder
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
}
