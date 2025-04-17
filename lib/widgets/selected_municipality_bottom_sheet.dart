import 'package:flutter/material.dart';

// Import the data model and other necessary classes
import '../models/data_model.dart';

class SelectedMunicipalityBottomSheet extends StatelessWidget {
  final DataModel location;
  final bool isExpanded;
  final double sheetHeight;
  final Function() onClose;
  final Function(DragUpdateDetails) onDragUpdate;
  // Municipality data
  final int? municipalityPopulation;
  // Add beneficiary data parameters
  final Map<String, int> beneficiaryData;
  final Map<String, int?> categoryTotals;
  final String selectedFilter;

  const SelectedMunicipalityBottomSheet({
    Key? key,
    required this.location,
    required this.isExpanded,
    required this.sheetHeight,
    required this.onClose,
    required this.onDragUpdate,
    this.municipalityPopulation,
    this.beneficiaryData = const {},
    this.categoryTotals = const {},
    this.selectedFilter = 'General',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

              // Municipality header
              _buildMunicipalityHeader(),

              // Divider for visual separation
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

              // Municipality content when expanded
              isExpanded
                  ? Expanded(
                      child: _buildMunicipalityContent(),
                    )
                  : const SizedBox.shrink(),
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

  Widget _buildMunicipalityHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Lat: ${location.latitude.toStringAsFixed(4)}, Long: ${location.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
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

  Widget _buildMunicipalityContent() {
    // Get beneficiary values with null safety
    int? healthcareBeneficiaries = beneficiaryData['Healthcare'];
    int? socialBeneficiaries = beneficiaryData['Social'];
    int? educationalBeneficiaries = beneficiaryData['Educational'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Municipality population card
          _buildInfoCard(
            'Population',
            municipalityPopulation != null
                ? _formatNumber(municipalityPopulation!)
                : 'Data not available',
            Icons.people,
            Colors.grey.shade700,
            Colors.blue,
            isHighlighted: selectedFilter == 'General',
          ),

          const SizedBox(height: 16),

          // Section header for beneficiaries
          Text(
            'Beneficiaries in ${location.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Healthcare Beneficiaries
          _buildInfoCard(
            'Healthcare Beneficiaries',
            healthcareBeneficiaries != null
                ? _formatNumber(healthcareBeneficiaries)
                : 'No data',
            Icons.local_hospital,
            Colors.red.shade100,
            Colors.red.shade600,
            isHighlighted: selectedFilter == 'Healthcare',
          ),

          const SizedBox(height: 12),

          // Social Beneficiaries
          _buildInfoCard(
            'Social Beneficiaries',
            socialBeneficiaries != null
                ? _formatNumber(socialBeneficiaries)
                : 'No data',
            Icons.people,
            Colors.green.shade100,
            Colors.green.shade600,
            isHighlighted: selectedFilter == 'Social',
          ),

          const SizedBox(height: 12),

          // Educational Beneficiaries
          _buildInfoCard(
            'Educational Beneficiaries',
            educationalBeneficiaries != null
                ? _formatNumber(educationalBeneficiaries)
                : 'No data',
            Icons.school,
            Colors.blue.shade100,
            Colors.blue.shade600,
            isHighlighted: selectedFilter == 'Educational',
          ),

          // Provincial statistics section
          const SizedBox(height: 24),
          Text(
            'Quezon Province Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // Display provincial totals with percentages
          if (municipalityPopulation != null &&
              categoryTotals['Healthcare'] != null)
            _buildStatisticRow(
              'Healthcare Coverage',
              healthcareBeneficiaries,
              categoryTotals['Healthcare']!,
              Colors.red.shade600,
            ),

          if (municipalityPopulation != null &&
              categoryTotals['Social'] != null)
            _buildStatisticRow(
              'Social Welfare Coverage',
              socialBeneficiaries,
              categoryTotals['Social']!,
              Colors.green.shade600,
            ),

          if (municipalityPopulation != null &&
              categoryTotals['Educational'] != null)
            _buildStatisticRow(
              'Educational Coverage',
              educationalBeneficiaries,
              categoryTotals['Educational']!,
              Colors.blue.shade600,
            ),
        ],
      ),
    );
  }

  // Helper widget to build consistent statistic rows with progress indicators
  Widget _buildStatisticRow(
      String title, int? localValue, int totalValue, Color color) {
    if (localValue == null) return const SizedBox.shrink();

    double percentage = (localValue / totalValue) * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title)),
              Text(
                '${percentage.toStringAsFixed(1)}% of province',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatNumber(localValue)} of ${_formatNumber(totalValue)} beneficiaries',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build consistent info cards
  Widget _buildInfoCard(
      String title, String value, IconData icon, Color bgColor, Color iconColor,
      {bool isHighlighted = false}) {
    return Card(
      elevation: isHighlighted ? 3 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlighted
            ? BorderSide(color: iconColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format large numbers with commas
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
