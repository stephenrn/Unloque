import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:data_table_2/data_table_2.dart';

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

          // Add a DataTable for beneficiaries
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beneficiary Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: _buildBeneficiaryDataTable(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Add comparison chart between municipality and provincial averages
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coverage Comparison',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: _buildComparisonChart(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Municipality vs Provincial Average',
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

          const SizedBox(height: 16),

          // Provincial statistics section
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

  // New method to build beneficiary data table
  Widget _buildBeneficiaryDataTable() {
    final List<Map<String, dynamic>> data = [
      {
        'category': 'Healthcare',
        'beneficiaries': beneficiaryData['Healthcare'] ?? 0,
        'color': Colors.red[600],
        'icon': Icons.local_hospital,
      },
      {
        'category': 'Social',
        'beneficiaries': beneficiaryData['Social'] ?? 0,
        'color': Colors.green[600],
        'icon': Icons.people,
      },
      {
        'category': 'Educational',
        'beneficiaries': beneficiaryData['Educational'] ?? 0,
        'color': Colors.blue[600],
        'icon': Icons.school,
      },
      {
        'category': 'Total',
        'beneficiaries': (beneficiaryData['Healthcare'] ?? 0) +
            (beneficiaryData['Social'] ?? 0) +
            (beneficiaryData['Educational'] ?? 0),
        'color': Colors.purple[600],
        'icon': Icons.pie_chart,
      },
    ];

    return DataTable2(
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
            '% of Pop',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          size: ColumnSize.S,
          numeric: true,
        ),
      ],
      rows: data.map((item) {
        // Calculate percentage of municipal population
        double percentage = 0;
        if (municipalityPopulation != null && municipalityPopulation! > 0) {
          percentage = (item['beneficiaries'] / municipalityPopulation!) * 100;
        }

        bool isTotal = item['category'] == 'Total';

        return DataRow2(
          color: isTotal ? MaterialStateProperty.all(Colors.grey[100]) : null,
          cells: [
            DataCell(
              Row(
                children: [
                  Icon(item['icon'], color: item['color'], size: 16),
                  SizedBox(width: 8),
                  Text(
                    item['category'],
                    style: TextStyle(
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
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
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // New method to build comparison chart
  Widget _buildComparisonChart() {
    // Calculate municipality coverage (beneficiaries as % of population)
    double healthcarePercentage = 0;
    double socialPercentage = 0;
    double educationalPercentage = 0;

    if (municipalityPopulation != null && municipalityPopulation! > 0) {
      healthcarePercentage =
          (beneficiaryData['Healthcare'] ?? 0) / municipalityPopulation! * 100;
      socialPercentage =
          (beneficiaryData['Social'] ?? 0) / municipalityPopulation! * 100;
      educationalPercentage =
          (beneficiaryData['Educational'] ?? 0) / municipalityPopulation! * 100;
    }

    // Calculate provincial averages for comparison
    double provincialHealthcarePercentage = 0;
    double provincialSocialPercentage = 0;
    double provincialEducationalPercentage = 0;

    if (categoryTotals['Healthcare'] != null &&
        categoryTotals['Social'] != null &&
        categoryTotals['Educational'] != null) {
      if (categoryTotals['Total Population'] != null &&
          categoryTotals['Total Population']! > 0) {
        final totalPop = categoryTotals['Total Population']!;
        provincialHealthcarePercentage =
            categoryTotals['Healthcare']! / totalPop * 100;
        provincialSocialPercentage = categoryTotals['Social']! / totalPop * 100;
        provincialEducationalPercentage =
            categoryTotals['Educational']! / totalPop * 100;
      }
    }

    final barWidth = 22.0;
    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: healthcarePercentage,
            color: Colors.red[400],
            width: barWidth,
          ),
          BarChartRodData(
            toY: provincialHealthcarePercentage,
            color: Colors.red[200],
            width: barWidth,
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: socialPercentage,
            color: Colors.green[400],
            width: barWidth,
          ),
          BarChartRodData(
            toY: provincialSocialPercentage,
            color: Colors.green[200],
            width: barWidth,
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: educationalPercentage,
            color: Colors.blue[400],
            width: barWidth,
          ),
          BarChartRodData(
            toY: provincialEducationalPercentage,
            color: Colors.blue[200],
            width: barWidth,
          ),
        ],
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 30, // Max 30% for better visibility
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const titles = ['Healthcare', 'Social', 'Educational'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          titles[value.toInt()],
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '${value.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(location.name, Colors.grey[800]!, true),
            const SizedBox(width: 24),
            _buildLegendItem('Provincial Average', Colors.grey[500]!, false),
          ],
        ),
      ],
    );
  }

  // Helper method for chart legend
  Widget _buildLegendItem(String label, Color textColor, bool isDarker) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue[isDarker ? 400 : 200]!,
                Colors.green[isDarker ? 400 : 200]!,
                Colors.red[isDarker ? 400 : 200]!,
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
          ),
        ),
      ],
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
