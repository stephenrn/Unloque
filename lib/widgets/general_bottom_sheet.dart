import 'package:flutter/material.dart';

// Import the data model and other necessary classes
import '../models/data_model.dart';
import '../services/ai_insights_service.dart';
import '../services/api_keys.dart';
import '../widgets/markdown_renderer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class GeneralBottomSheet extends StatefulWidget {
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
  // Add new parameters for the raw data needed for AI analysis
  final Map<String, int>? rawPopulationData;
  final Map<String, Map<String, int>>? categoryData;

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
    this.totalPopulation,
    this.healthcareTotalBeneficiaries,
    this.socialTotalBeneficiaries,
    this.educationTotalBeneficiaries,
    this.rawPopulationData,
    this.categoryData,
  }) : super(key: key);

  @override
  State<GeneralBottomSheet> createState() => _GeneralBottomSheetState();
}

class _GeneralBottomSheetState extends State<GeneralBottomSheet> {
  // State variables for AI-generated content
  bool _isLoadingDataSummary = false;
  bool _isLoadingInsights = false;
  String _dataSummaryContent = '';
  String _insightsContent = '';
  String? _dataSummaryError;
  String? _insightsError;

  // Flag to track if tabs have been selected and need data loading
  bool _dataSummaryTabSelected = false;
  bool _insightsTabSelected = false;

  @override
  void initState() {
    super.initState();
    // Listen for tab changes
    widget.tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    // Clean up listeners
    widget.tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  // Handle tab changes
  void _handleTabChange() {
    if (!widget.tabController.indexIsChanging) {
      // Data Analysis tab is index 0
      // Data Summary tab is index 1
      // Insights tab is index 2

      if (widget.tabController.index == 1 && !_dataSummaryTabSelected) {
        setState(() {
          _dataSummaryTabSelected = true;
        });
        _generateDataSummary();
      }

      if (widget.tabController.index == 2 && !_insightsTabSelected) {
        setState(() {
          _insightsTabSelected = true;
        });
        _generateInsights();
      }
    }
  }

  // Generate data summary using AI
  Future<void> _generateDataSummary() async {
    // Only proceed if we have the necessary data
    if (widget.rawPopulationData == null || widget.categoryData == null) {
      setState(() {
        _dataSummaryError = 'Insufficient data available for analysis';
      });
      return;
    }

    setState(() {
      _isLoadingDataSummary = true;
      _dataSummaryError = null;
      _dataSummaryContent = ''; // Clear previous content
    });

    try {
      // Prepare category totals map
      Map<String, int?> categoryTotals = {
        'Healthcare': widget.healthcareTotalBeneficiaries,
        'Social': widget.socialTotalBeneficiaries,
        'Educational': widget.educationTotalBeneficiaries,
      };

      final summary = await AIInsightsService.generateDataSummary(
        populationData: Map<String, dynamic>.from(widget.rawPopulationData!),
        categoryData: widget.categoryData!,
        totalPopulation: widget.totalPopulation,
        categoryTotals: categoryTotals,
      );

      setState(() {
        _dataSummaryContent = summary;
        _isLoadingDataSummary = false;
      });
    } catch (e) {
      setState(() {
        _dataSummaryError =
            'Failed to generate data summary. Please try again.';
        _isLoadingDataSummary = false;
      });
    }
  }

  // Generate insights using AI
  Future<void> _generateInsights() async {
    // Only proceed if we have the necessary data
    if (widget.rawPopulationData == null || widget.categoryData == null) {
      setState(() {
        _insightsError = 'Insufficient data available for analysis';
      });
      return;
    }

    setState(() {
      _isLoadingInsights = true;
      _insightsError = null;
      _insightsContent = ''; // Clear previous content
    });

    try {
      // Prepare category totals map
      Map<String, int?> categoryTotals = {
        'Healthcare': widget.healthcareTotalBeneficiaries,
        'Social': widget.socialTotalBeneficiaries,
        'Educational': widget.educationTotalBeneficiaries,
      };

      final insights = await AIInsightsService.generateInsights(
        populationData: Map<String, dynamic>.from(widget.rawPopulationData!),
        categoryData: widget.categoryData!,
        totalPopulation: widget.totalPopulation,
        categoryTotals: categoryTotals,
      );

      setState(() {
        _insightsContent = insights;
        _isLoadingInsights = false;
      });
    } catch (e) {
      setState(() {
        _insightsError = 'Failed to generate insights. Please try again.';
        _isLoadingInsights = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: 0,
      left: 0,
      right: 0,
      height: widget.sheetHeight,
      child: GestureDetector(
        onVerticalDragUpdate: widget.onDragUpdate,
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

              if (widget.isExpanded) ...[
                // Tab bar
                _buildTabBar(),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: widget.tabController,
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
      onTap: widget.onToggleExpansion,
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
                  widget.location.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.totalPopulation != null)
                  Text(
                    'Population: ${_formatNumber(widget.totalPopulation!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.isDefaultView ==
              false) // Close button only if we are viewing a specific municipality
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 48,
      child: TabBar(
        controller: widget.tabController,
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
                    widget.totalPopulation != null
                        ? _formatNumber(widget.totalPopulation!)
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
                    widget.healthcareTotalBeneficiaries != null
                        ? _formatNumber(widget.healthcareTotalBeneficiaries!)
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
                    widget.socialTotalBeneficiaries != null
                        ? _formatNumber(widget.socialTotalBeneficiaries!)
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
                    widget.educationTotalBeneficiaries != null
                        ? _formatNumber(widget.educationTotalBeneficiaries!)
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
    // Updated to show AI-generated data summary
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Data Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              if (!_isLoadingDataSummary)
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _generateDataSummary,
                  tooltip: 'Refresh analysis',
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Display AI-powered analysis - removed Card container
          MarkdownRenderer(
            data: _dataSummaryContent,
            isLoading: _isLoadingDataSummary,
            errorMessage: _dataSummaryError,
            onRetry: _generateDataSummary,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    // Updated to show AI-generated insights
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Strategic Insights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              if (!_isLoadingInsights)
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _generateInsights,
                  tooltip: 'Refresh insights',
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Display AI-powered insights - removed Card container
          MarkdownRenderer(
            data: _insightsContent,
            isLoading: _isLoadingInsights,
            errorMessage: _insightsError,
            onRetry: _generateInsights,
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
