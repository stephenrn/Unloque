import 'package:flutter/material.dart';

// Import the data model and other necessary classes
import '../models/data_model.dart';

class GeneralBottomSheet extends StatelessWidget {
  final DataModel location;
  final bool isDefaultView;
  final bool isExpanded;
  final double sheetHeight;
  final Function() onClose;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function() onToggleExpansion;
  final TabController tabController;
  // Add new parameter to receive total population
  final int? totalPopulation;
  // Add parameters for category data totals
  final int? healthcareTotalBeneficiaries;
  final int? socialTotalBeneficiaries;
  final int? educationTotalBeneficiaries;

  const GeneralBottomSheet({
    Key? key,
    required this.location,
    required this.isDefaultView,
    required this.isExpanded,
    required this.sheetHeight,
    required this.onClose,
    required this.onDragUpdate,
    required this.onToggleExpansion,
    required this.tabController,
    this.totalPopulation, // Make it optional since it might be null during loading
    this.healthcareTotalBeneficiaries,
    this.socialTotalBeneficiaries,
    this.educationTotalBeneficiaries,
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

              // Location header with name and population
              _buildLocationHeader(),

              if (isExpanded) ...[
                // Tab bar
                _buildTabBar(),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      _buildDataAnalysisTab(),
                      _buildDataSummaryTab(),
                      _buildInsightsTab(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return GestureDetector(
      onTap: onToggleExpansion,
      child: Container(
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
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 50, // Fixed height for header area
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
                if (totalPopulation != null)
                  Text(
                    'Population: ${_formatNumber(totalPopulation!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          if (isDefaultView ==
              false) // Close button only if we are viewing a specific municipality
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

  Widget _buildTabBar() {
    return SizedBox(
      height: 48,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        indicatorWeight: 3.0,
        tabs: const [
          Tab(text: 'Data Analysis'),
          Tab(text: 'Data Summary'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildDataAnalysisTab() {
    // Updated to show category totals
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Beneficiaries by Category',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),

          // Total Population card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people,
                    size: 48,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Total Population',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalPopulation != null
                        ? _formatNumber(totalPopulation!)
                        : 'Loading...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quezon Province',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Healthcare Beneficiaries Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_hospital,
                    size: 48,
                    color: Colors.red[600],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Healthcare Beneficiaries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    healthcareTotalBeneficiaries != null
                        ? _formatNumber(healthcareTotalBeneficiaries!)
                        : 'Loading...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Social Beneficiaries Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 48,
                    color: Colors.green[600],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Social Beneficiaries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    socialTotalBeneficiaries != null
                        ? _formatNumber(socialTotalBeneficiaries!)
                        : 'Loading...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Education Beneficiaries Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 48,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Educational Beneficiaries', // Changed from 'Education Beneficiaries' to 'Educational Beneficiaries'
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    educationTotalBeneficiaries != null
                        ? _formatNumber(educationTotalBeneficiaries!)
                        : 'Loading...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryTab() {
    // Show empty content instead of population data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          // Additional summary widgets would go here
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50.0),
              child: Text(
                'Summary data coming soon',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    // Show empty content instead of population data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          // Insights content would go here
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50.0),
              child: Text(
                'Insights coming soon',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
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
