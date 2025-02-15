import 'package:flutter/material.dart';

class ApplicationProgressCard extends StatelessWidget {
  final String category;
  final String programName;
  final String deadline;
  final String status;
  final double progress;
  final Color categoryColor;
  final IconData organizationLogo; // Added this line

  const ApplicationProgressCard({
    super.key,
    required this.category,
    required this.programName,
    required this.deadline,
    required this.status,
    required this.progress,
    required this.categoryColor,
    required this.organizationLogo, // Added this line
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'ongoing':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180, // Reduced from 190
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: categoryColor, // Using original categoryColor instead of lightBackgroundColor
        borderRadius: BorderRadius.circular(15),
        // Removed border property
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // TODO: Navigate to details page
          },
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                          child: Center(
                            child: Icon(
                              organizationLogo,
                              size: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white, // Changed from _getStatusColor().withOpacity(0.2)
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status, // Removed .toUpperCase()
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      category, // Removed .toUpperCase()
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,  // Changed from categoryColor to Colors.black
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      programName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.black87),
                        SizedBox(width: 4),
                        Text(
                          '$deadline',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${progress.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: List.generate(4, (index) {
                        final segmentProgress = (progress / 100 * 4).floor();
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 2),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index < segmentProgress 
                                  ? Colors.black // Changed from _getProgressColor()
                                  : Colors.grey[200],
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
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 0,
                            blurRadius: 2,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'View Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
