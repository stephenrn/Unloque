import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:data_table_2/data_table_2.dart';

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
      debugPrint('GeneralBottomSheet: Generating data summary');
      debugPrint('Population data items: ${widget.rawPopulationData!.length}');
      debugPrint('Total population: ${widget.totalPopulation}');

      // Create a deep copy of the raw population data to ensure it's mutable
      final populationData =
          Map<String, dynamic>.from(widget.rawPopulationData!);

      // Explicitly add the total population to ensure it's available
      if (widget.totalPopulation != null) {
        populationData['Total Population'] = widget.totalPopulation;
        debugPrint(
            'Added Total Population key with value: ${widget.totalPopulation}');
      } else {
        debugPrint('WARNING: Total population is null');
      }

      // Prepare category totals map
      Map<String, int?> categoryTotals = {
        'Total Population': widget.totalPopulation,
        'Healthcare': widget.healthcareTotalBeneficiaries,
        'Social': widget.socialTotalBeneficiaries,
        'Educational': widget.educationTotalBeneficiaries,
      };

      final summary = await AIInsightsService.generateDataSummary(
        populationData: populationData,
        categoryData: widget.categoryData!,
        totalPopulation: widget.totalPopulation,
        categoryTotals: categoryTotals,
      );

      setState(() {
        _dataSummaryContent = summary;
        _isLoadingDataSummary = false;
      });
    } catch (e) {
      debugPrint('Error generating data summary: $e');
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
      debugPrint('GeneralBottomSheet: Generating insights');
      debugPrint('Population data items: ${widget.rawPopulationData!.length}');
      debugPrint('Total population: ${widget.totalPopulation}');

      // Create a deep copy of the raw population data to ensure it's mutable
      final populationData =
          Map<String, dynamic>.from(widget.rawPopulationData!);

      // Explicitly add the total population to ensure it's available
      if (widget.totalPopulation != null) {
        populationData['Total Population'] = widget.totalPopulation;
        debugPrint(
            'Added Total Population key with value: ${widget.totalPopulation}');
      } else {
        debugPrint('WARNING: Total population is null');
      }

      // Prepare category totals map
      Map<String, int?> categoryTotals = {
        'Total Population': widget.totalPopulation,
        'Healthcare': widget.healthcareTotalBeneficiaries,
        'Social': widget.socialTotalBeneficiaries,
        'Educational': widget.educationTotalBeneficiaries,
      };

      final insights = await AIInsightsService.generateInsights(
        populationData: populationData,
        categoryData: widget.categoryData!,
        totalPopulation: widget.totalPopulation,
        categoryTotals: categoryTotals,
      );

      setState(() {
        _insightsContent = insights;
        _isLoadingInsights = false;
      });
    } catch (e) {
      debugPrint('Error generating insights: $e');
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
    // Updated to include charts and DataTable
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

          // Add population data card with bar chart
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Population',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.totalPopulation != null
                            ? _formatNumber(widget.totalPopulation!)
                            : 'Loading...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Population Chart - Top 5 Municipalities
                  _buildTopMunicipalitiesChart(),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Top 5 Municipalities by Population',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Category breakdown pie chart
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welfare Category Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Program Category Pie Chart
                  SizedBox(
                    height: 200,
                    child: _buildCategoryPieChart(),
                  ),

                  const SizedBox(height: 16),

                  // Legend for the chart
                  _buildChartLegend(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Beneficiary DataTable
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welfare Program Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DataTable for category totals
                  _buildBeneficiaryDataTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New method to build beneficiary DataTable
  Widget _buildBeneficiaryDataTable() {
    final List<Map<String, dynamic>> data = [
      {
        'category': 'Healthcare',
        'beneficiaries': widget.healthcareTotalBeneficiaries ?? 0,
        'color': Colors.red[600],
        'icon': Icons.local_hospital,
      },
      {
        'category': 'Social',
        'beneficiaries': widget.socialTotalBeneficiaries ?? 0,
        'color': Colors.green[600],
        'icon': Icons.people,
      },
      {
        'category': 'Educational',
        'beneficiaries': widget.educationTotalBeneficiaries ?? 0,
        'color': Colors.blue[600],
        'icon': Icons.school,
      },
      {
        'category': 'Total Beneficiaries',
        'beneficiaries': (widget.healthcareTotalBeneficiaries ?? 0) +
            (widget.socialTotalBeneficiaries ?? 0) +
            (widget.educationTotalBeneficiaries ?? 0),
        'color': Colors.purple[600],
        'icon': Icons.pie_chart,
      },
    ];

    return Container(
      height: 220,
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 300,
        columns: [
          DataColumn2(
            label: Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text(
              'Beneficiaries',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            size: ColumnSize.M,
            numeric: true,
          ),
          DataColumn2(
            label: Text(
              'Ratio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            size: ColumnSize.S,
            numeric: true,
          ),
        ],
        rows: data.map((item) {
          // Calculate ratio based on total population
          double ratio = 0;
          if (widget.totalPopulation != null && widget.totalPopulation! > 0) {
            ratio = (item['beneficiaries'] / widget.totalPopulation!) * 100;
          }

          bool isTotal = item['category'] == 'Total Beneficiaries';

          return DataRow2(
            color: isTotal ? MaterialStateProperty.all(Colors.grey[100]) : null,
            cells: [
              DataCell(
                // Fix overflow issue by using a Row with Expanded
                Flexible(
                  child: Row(
                    children: [
                      Icon(item['icon'], color: item['color'], size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['category'],
                          style: TextStyle(
                            fontWeight:
                                isTotal ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatNumber(item['beneficiaries']),
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    color: item['color'],
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${ratio.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // New method to build category pie chart
  Widget _buildCategoryPieChart() {
    // Get total for each category
    final double healthcare =
        widget.healthcareTotalBeneficiaries?.toDouble() ?? 0;
    final double social = widget.socialTotalBeneficiaries?.toDouble() ?? 0;
    final double education =
        widget.educationTotalBeneficiaries?.toDouble() ?? 0;

    // Calculate total for percentage
    final double total = healthcare + social + education;

    // Handle case where we have no data
    if (total <= 0) {
      return Center(
        child: Text('No beneficiary data available'),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.red[400]!,
            value: healthcare,
            title: '${(healthcare / total * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.green[400]!,
            value: social,
            title: '${(social / total * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.blue[400]!,
            value: education,
            title: '${(education / total * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: 180,
      ),
    );
  }

  // Legend for the pie chart
  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Healthcare', Colors.red[400]!),
        const SizedBox(width: 24),
        _legendItem('Social', Colors.green[400]!),
        const SizedBox(width: 24),
        _legendItem('Educational', Colors.blue[400]!),
      ],
    );
  }

  // Helper for legend items
  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // New method to build top municipalities chart
  Widget _buildTopMunicipalitiesChart() {
    // Extract and sort municipalities by population
    List<MapEntry<String, int>> sortedMunicipalities = [];

    if (widget.rawPopulationData != null) {
      sortedMunicipalities = widget.rawPopulationData!.entries
          .where((entry) => entry.key != 'Total Population') // exclude total
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // sort descending

      // Only take top 5
      if (sortedMunicipalities.length > 5) {
        sortedMunicipalities = sortedMunicipalities.sublist(0, 5);
      }
    }

    if (sortedMunicipalities.isEmpty) {
      return Center(
        child: Text('Population data not available'),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: sortedMunicipalities.first.value * 1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= sortedMunicipalities.length) {
                    return const Text('');
                  }
                  // Abbreviate municipality names
                  String name = sortedMunicipalities[value.toInt()].key;
                  if (name.length > 8) {
                    name = name.substring(0, 6) + '...';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String text = '';
                  if (value >= 1000) {
                    text = '${(value / 1000).toStringAsFixed(0)}K';
                  } else {
                    text = value.toStringAsFixed(0);
                  }
                  return Text(
                    text,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: sortedMunicipalities.first.value / 5,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: List.generate(
            sortedMunicipalities.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: sortedMunicipalities[index].value.toDouble(),
                  color: Colors.blue[400],
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                )
              ],
            ),
          ),
        ),
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
