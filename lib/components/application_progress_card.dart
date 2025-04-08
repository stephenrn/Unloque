import 'package:flutter/material.dart';
import 'package:unloque/pages/application_form_page.dart';
import 'package:unloque/data/available_applications_data.dart';

class ApplicationProgressCard extends StatelessWidget {
  final String category;
  final String programName;
  final String deadline;
  final String status;
  final Color categoryColor;
  final IconData organizationLogo;
  final String organizationName;
  final String id;

  const ApplicationProgressCard({
    super.key,
    required this.category,
    required this.programName,
    required this.deadline,
    required this.status,
    required this.categoryColor,
    required this.organizationLogo,
    required this.organizationName,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: categoryColor ?? Colors.grey, // Handle null categoryColor
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            final applicationDetails =
                AvailableApplicationsData.getAllApplications().firstWhere(
              (app) => app['id'] == id,
              orElse: () => {}, // Handle missing application details
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplicationFormPage(application: {
                  ...applicationDetails,
                  'status': status,
                }),
              ),
            );
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                organizationLogo ??
                                    Icons
                                        .help_outline, // Provide a default value if null
                                size: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.isNotEmpty
                                    ? status
                                    : 'Unknown', // Handle null or empty status
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          category.isNotEmpty ? category : 'Unknown',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.only(
                        left: 12, right: 12, top: 20, bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.black87),
                            SizedBox(width: 4),
                            Text(
                              deadline.isNotEmpty ? deadline : 'No Deadline',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 3),
                        Row(
                          children: List.generate(3, (index) {
                            final int segmentProgress;
                            if (status == 'Ongoing') {
                              segmentProgress = 1;
                            } else if (status == 'Pending') {
                              segmentProgress = 2;
                            } else if (status == 'Completed') {
                              segmentProgress = 3;
                            } else {
                              segmentProgress = 0;
                            }
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: index < segmentProgress
                                      ? Colors.black
                                      : Colors.grey[200] ??
                                          Colors.grey, // Provide fallback color
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.1),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800] ??
                                Colors.black, // Provide fallback color
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.grey[800] ??
                                Colors.black, // Provide fallback color
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_outward_rounded,
                            color: Colors.grey[200] ??
                                Colors.grey, // Provide fallback color
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 60,
                left: 12,
                right: 12,
                child: Text(
                  programName.isNotEmpty ? programName : 'Unknown Program',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
