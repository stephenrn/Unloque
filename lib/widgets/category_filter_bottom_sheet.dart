import 'package:flutter/material.dart';

// Import the data model and other necessary classes
import '../models/data_model.dart';

class CategoryFilterBottomSheet extends StatelessWidget {
  final DataModel location;
  final bool isDefaultView;
  final bool isExpanded;
  final double sheetHeight;
  final String selectedFilter;
  final Function() onClose;
  final Function(DragUpdateDetails) onDragUpdate;

  const CategoryFilterBottomSheet({
    Key? key,
    required this.location,
    required this.isDefaultView,
    required this.isExpanded,
    required this.sheetHeight,
    required this.selectedFilter,
    required this.onClose,
    required this.onDragUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine category color based on selected filter
    Color categoryColor;
    IconData categoryIcon;

    switch (selectedFilter) {
      case 'Healthcare':
        categoryColor = Colors.red.shade600;
        categoryIcon = Icons.local_hospital;
        break;
      case 'Social':
        categoryColor = Colors.purple.shade600;
        categoryIcon = Icons.people;
        break;
      case 'Education':
        categoryColor = Colors.green.shade600;
        categoryIcon = Icons.school;
        break;
      default:
        categoryColor = Colors.blue.shade600;
        categoryIcon = Icons.category;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: 0,
      left: 0,
      right: 0,
      height: sheetHeight,
      child: GestureDetector(
        onVerticalDragUpdate: onDragUpdate,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              _buildDragHandle(),

              // Category header with icon and title
              _buildCategoryHeader(categoryColor, categoryIcon),

              // Divider for visual separation
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

              // Category-specific content
              if (isExpanded)
                Expanded(
                  child: _buildCategoryContent(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: double.infinity,
      height: 16,
      alignment: Alignment.center,
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(Color categoryColor, IconData categoryIcon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 50, // Fixed height for header area
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            categoryIcon,
            color: categoryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selectedFilter in ${location.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: categoryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isDefaultView
                      ? 'Province-wide $selectedFilter overview'
                      : 'Local $selectedFilter services and facilities',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (selectedFilter) {
      case 'Healthcare':
        return _buildHealthcareContent();
      case 'Social':
        return _buildSocialContent();
      case 'Education':
        return _buildEducationContent();
      default:
        return Container();
    }
  }

  // Healthcare content
  Widget _buildHealthcareContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDefaultView
                ? 'Healthcare Facilities in Quezon Province'
                : 'Healthcare Facilities in ${location.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildFacilityCard(
            'Hospitals',
            isDefaultView
                ? '24 provincial hospitals'
                : '${_getMunicipalityHospitalCount(location.name)} local hospitals',
            Icons.local_hospital,
            Colors.red.shade100,
          ),
          _buildFacilityCard(
            'Rural Health Units',
            isDefaultView ? '39 RHUs province-wide' : '1 rural health unit',
            Icons.healing,
            Colors.red.shade100,
          ),
          _buildFacilityCard(
            'Barangay Health Stations',
            isDefaultView
                ? '450+ across the province'
                : '8 barangay health stations',
            Icons.health_and_safety,
            Colors.red.shade100,
          ),
          const SizedBox(height: 24),
          const Text(
            'Health Indicators',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildHealthIndicator(
              'Access to Healthcare', '68%', Colors.red.shade600),
          _buildHealthIndicator('Immunization Rate', '76%', Colors.orange),
          _buildHealthIndicator('Maternal Care Coverage', '82%', Colors.green),
        ],
      ),
    );
  }

  // Social welfare content
  Widget _buildSocialContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDefaultView
                ? 'Social Welfare Programs in Quezon Province'
                : 'Social Services in ${location.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildFacilityCard(
            '4Ps Beneficiaries',
            isDefaultView
                ? '145,620 households'
                : '${_getMunicipality4PsCount(location.name)} households',
            Icons.family_restroom,
            Colors.purple.shade100,
          ),
          _buildFacilityCard(
            'Social Pension Recipients',
            isDefaultView ? '56,780 senior citizens' : '1,250 senior citizens',
            Icons.elderly,
            Colors.purple.shade100,
          ),
          _buildFacilityCard(
            'Disaster Relief Centers',
            isDefaultView ? '42 evacuation centers' : '3 evacuation centers',
            Icons.house,
            Colors.purple.shade100,
          ),
          const SizedBox(height: 24),
          const Text(
            'Community Development',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildProgramCard(
            'Livelihood Programs',
            'Skills training and micro-enterprise development',
            Icons.work,
          ),
          _buildProgramCard(
            'Community-Based Rehabilitation',
            'Support for persons with disabilities',
            Icons.accessibility_new,
          ),
        ],
      ),
    );
  }

  // Education content
  Widget _buildEducationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDefaultView
                ? 'Education in Quezon Province'
                : 'Educational Facilities in ${location.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildFacilityCard(
            'Public Schools',
            isDefaultView
                ? '765 elementary and high schools'
                : '${_getMunicipalitySchoolCount(location.name)} public schools',
            Icons.school,
            Colors.green.shade100,
          ),
          _buildFacilityCard(
            'Private Schools',
            isDefaultView ? '124 accredited institutions' : '3 private schools',
            Icons.apartment,
            Colors.green.shade100,
          ),
          _buildFacilityCard(
            'Higher Education',
            isDefaultView ? '15 colleges and universities' : '1 college campus',
            Icons.account_balance,
            Colors.green.shade100,
          ),
          const SizedBox(height: 24),
          const Text(
            'Education Indicators',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildHealthIndicator('Literacy Rate', '96.7%', Colors.green),
          _buildHealthIndicator(
              'Enrollment Rate', '92%', Colors.green.shade600),
          _buildHealthIndicator('Completion Rate', '88%', Colors.amber),
        ],
      ),
    );
  }

  // Helper methods for municipality-specific data
  int _getMunicipalityHospitalCount(String municipality) {
    // In a real app, this would come from a database
    // For now, return different values based on municipality name length
    return (municipality.length % 3) + 1; // 1-3 hospitals based on name length
  }

  String _getMunicipality4PsCount(String municipality) {
    // Generate realistic values based on municipality name
    return '${(municipality.length * 100) + 500}';
  }

  int _getMunicipalitySchoolCount(String municipality) {
    return municipality.length + 5; // Simple formula for demo purposes
  }

  // Helper widgets for category contents
  Widget _buildFacilityCard(
      String title, String count, IconData icon, Color bgColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(count),
      ),
    );
  }

  Widget _buildProgramCard(String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.purple.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String label, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                percentage,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: double.parse(percentage.replaceAll('%', '')) / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}
