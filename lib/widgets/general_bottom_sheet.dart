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
              // Fixed-size drag handle area
              _buildDragHandle(),

              // Location header
              _buildLocationHeader(),

              // Divider for visual separation
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

              // Show different content based on whether we're showing Quezon Province or a specific municipality
              if (isDefaultView) // Only show tabs for Quezon Province
                Expanded(
                  child: Column(
                    children: [
                      // Tab Bar with fixed height
                      _buildTabBar(),

                      // Tab content with consistent padding
                      if (isExpanded)
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
                  ),
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
                const SizedBox(height: 2),
                isDefaultView
                    ? const Text(
                        'Explore municipalities and cities',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      )
                    : Text(
                        'Lat: ${location.latitude.toStringAsFixed(4)}, Long: ${location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
              ],
            ),
          ),
          if (!isDefaultView)
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
      height: 40, // Fixed height for tab bar
      child: TabBar(
        controller: tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        labelStyle: const TextStyle(fontSize: 14),
        indicatorWeight: 2.0,
        tabs: const [
          Tab(text: 'Data Analysis'),
          Tab(text: 'Data Summary'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildDataAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Analysis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          isDefaultView
              ? const Text(
                  'Statistical analysis for Quezon Province showing demographic trends, '
                  'economic indicators, and geographical data distributions.')
              : Text(
                  'Analysis for ${location.name} showing key metrics and comparative data '
                  'with other municipalities in Quezon Province.'),
          const SizedBox(height: 16),
          // Placeholder for charts or data visualizations
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Chart: Population Trends for ${location.name}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          isDefaultView ? _buildProvinceDataSummary() : _buildDataUnavailable(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProvinceDataSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Total Area', '8,706.60 km²'),
        _buildDataRow('Population (2020)', '1,950,459'),
        _buildDataRow('Population Density', '224/km²'),
        _buildDataRow('Number of Municipalities', '39'),
        _buildDataRow('Number of Cities', '2'),
        _buildDataRow('Capital', 'Lucena City'),
        _buildDataRow('Regional Classification', 'CALABARZON (Region IV-A)'),
      ],
    );
  }

  Widget _buildDataUnavailable() {
    return const Text('Detailed data not available for this location.');
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          isDefaultView
              ? const Text(
                  'Quezon Province is known for its agricultural production, particularly coconut. '
                  'The province faces challenges such as development disparities between coastal and inland areas, '
                  'vulnerability to typhoons, and managing its natural resources sustainably.')
              : Text(
                  'Insights for ${location.name} will be displayed here, including '
                  'local economic opportunities, development challenges, and unique characteristics.'),
          const SizedBox(height: 16),
          const Text(
            'Key Observations:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildInsightPoint('1. Economic Potential',
              'Tourism and agriculture present significant growth opportunities.'),
          _buildInsightPoint('2. Development Challenges',
              'Infrastructure gaps and climate vulnerability need addressing.'),
          _buildInsightPoint('3. Recommendations',
              'Focus on sustainable development and economic diversification.'),
        ],
      ),
    );
  }

  Widget _buildInsightPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }
}
