import 'package:flutter/material.dart';
import '../data/available_applications_data.dart';
import 'application_details_page.dart';

class CategoryDetailsPage extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;

  const CategoryDetailsPage({
    super.key,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Force clearing cache to ensure fresh data
      AvailableApplicationsData.clearCache();

      final applications =
          await AvailableApplicationsData.getApplicationsByCategory(
              widget.categoryName);

      setState(() {
        _applications = applications;
      });
    } catch (e) {
      print('Error loading applications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        toolbarHeight: 140,
        automaticallyImplyLeading: false,
        flexibleSpace: Padding(
          padding: EdgeInsets.fromLTRB(16, 40, 16, 0),
          child: Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context, true),
                  icon: Transform.rotate(
                    angle: 4.71239,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.grey[900],
                      size: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    widget.categoryName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[200],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _applications.isEmpty
                ? Center(
                    child: Text(
                      'No available applications',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        EdgeInsets.only(top: 50, bottom: 0, left: 0, right: 0),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) => AvailableApplicationCard(
                      application: _applications[index],
                    ),
                  ),
      ),
    );
  }
}

class AvailableApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const AvailableApplicationCard({
    super.key,
    required this.application,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate to details and await result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicationDetailsPage(
              application: application,
            ),
          ),
        );

        // If a refresh is requested (result is true), propagate refresh upward
        if (result == true) {
          // Find the nearest CategoryDetailsPage state and refresh it
          final categoryDetailsState =
              context.findAncestorStateOfType<_CategoryDetailsPageState>();
          if (categoryDetailsState != null) {
            categoryDetailsState._loadApplications();
          }

          // Also propagate to parent if needed
          Navigator.of(context).pop(true);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[500]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Replace Icon with Image container
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: application['logoUrl'] != null &&
                                  application['logoUrl'].toString().isNotEmpty
                              ? Image.network(
                                  application['logoUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      size: 18,
                                      color: Colors.grey[800],
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.business,
                                  size: 18,
                                  color: Colors.grey[800],
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        application['organizationName'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    application['programName'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 30), // More space after program name
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Due on    ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        TextSpan(
                          text: application['deadline'],
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ApplicationDetailsPage(application: application),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(
                  color: application['categoryColor'],
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        color: Colors.grey[200],
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
