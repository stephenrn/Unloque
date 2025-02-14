import 'package:flutter/material.dart';

class ApplicationProgressCard extends StatelessWidget {
  final String category;
  final String programName;
  final String deadline;
  final String status;
  final double progress;
  final Color categoryColor;

  const ApplicationProgressCard({
    super.key,
    required this.category,
    required this.programName,
    required this.deadline,
    required this.status,
    required this.progress,
    required this.categoryColor,
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

  Color _getProgressColor() {
    if (progress <= 30) return Colors.redAccent;
    if (progress <= 70) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180, // Increased from 160
      margin: EdgeInsets.symmetric(horizontal: 4), // Slightly increased margin
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15), // Increased from 12
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // TODO: Navigate to details page
          },
          child: Padding(
            padding: EdgeInsets.all(12), // Increased from 10
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Added this
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Increased padding
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11, // Increased from 9
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11, // Increased from 9
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8), // Increased from 6
                    Text(
                      programName,
                      style: TextStyle(
                        fontSize: 14, // Increased from 12
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[100],
                      ),
                      maxLines: 2, // Increased to 2 lines
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[100]), // Increased from 10
                        SizedBox(width: 4),
                        Text(
                          'Deadline: $deadline',
                          style: TextStyle(
                            fontSize: 11, // Increased from 9
                            color: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Progress section now in a separate Column at the bottom
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
                            fontSize: 11, // Increased from 9
                            color: Colors.grey[100],
                          ),
                        ),
                        Text(
                          '${progress.toInt()}%',
                          style: TextStyle(
                            fontSize: 11, // Increased from 9
                            fontWeight: FontWeight.bold,
                            color: _getProgressColor(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6), // Increased from 4
                    Row(
                      children: List.generate(4, (index) {
                        final segmentProgress = (progress / 100 * 4).floor();
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 2), // Increased from 1
                            height: 4, // Increased from 3
                            decoration: BoxDecoration(
                              color: index < segmentProgress 
                                  ? _getProgressColor()
                                  : Colors.white.withOpacity(0.3),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
