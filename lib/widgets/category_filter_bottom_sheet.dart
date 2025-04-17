import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:data_table_2/data_table_2.dart';

// Import the data model
import '../models/data_model.dart';

class CategoryFilterBottomSheet extends StatelessWidget {
  final String selectedFilter;
  final bool isExpanded;
  final double sheetHeight;
  final Function() onClose;
  final Function(DragUpdateDetails) onDragUpdate;
  final int? categoryTotalBeneficiaries;

  const CategoryFilterBottomSheet({
    Key? key,
    required this.selectedFilter,
    required this.isExpanded,
    required this.sheetHeight,
    required this.onClose,
    required this.onDragUpdate,
    this.categoryTotalBeneficiaries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine category color and icon based on selected filter
    Color categoryColor;
    IconData categoryIcon;

    switch (selectedFilter) {
      case 'Healthcare':
        categoryColor = Colors.red.shade600;
        categoryIcon = Icons.local_hospital;
        break;
      case 'Social':
        categoryColor = Colors.green.shade600;
        categoryIcon = Icons.people;
        break;
      case 'Educational':
        categoryColor = Colors.blue.shade600;
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

              // Category programs content when expanded
              isExpanded
                  ? Expanded(
                      child: _buildCategoryProgramsContent(),
                    )
                  : _buildCollapsedContent(categoryColor),
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
                  '$selectedFilter Programs',
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
                  'Available programs and beneficiary counts',
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

  // Simple collapsed content showing total beneficiaries
  Widget _buildCollapsedContent(Color categoryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total ${selectedFilter} Beneficiaries:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            categoryTotalBeneficiaries != null
                ? _formatNumber(categoryTotalBeneficiaries!)
                : 'Loading...',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Build the category programs content with Firestore data
  Widget _buildCategoryProgramsContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mapdata')
          .where('type', isEqualTo: 'beneficiaries')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error in mapdata stream: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No beneficiary data found in mapdata collection');
          return _buildNoDataContent();
        }

        // Filter documents by category based on program data
        return FutureBuilder<List<Map<String, dynamic>>>(
          future:
              _filterProgramsByCategory(snapshot.data!.docs, selectedFilter),
          builder: (context, programsSnapshot) {
            if (programsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (programsSnapshot.hasError) {
              print('Error filtering programs: ${programsSnapshot.error}');
              return Center(child: Text('Error: ${programsSnapshot.error}'));
            }

            if (!programsSnapshot.hasData || programsSnapshot.data!.isEmpty) {
              print('No matching programs found for category: $selectedFilter');
              return _buildNoDataContent();
            }

            final programs = programsSnapshot.data!;
            print(
                'Found ${programs.length} programs for category: $selectedFilter');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total beneficiaries for this category
                  _buildTotalBeneficiariesCard(selectedFilter),

                  const SizedBox(height: 24),

                  // New: Add beneficiaries distribution chart
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
                            'Municipal Distribution',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(selectedFilter),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: _buildMunicipalDistributionChart(programs),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Top 5 Municipalities by Beneficiary Count',
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

                  // Programs header
                  Text(
                    '${selectedFilter} Programs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // New: Programs DataTable
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
                            'Program Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: _buildProgramsDataTable(programs),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // List of programs
                  ...programs.map((program) => _buildProgramCard(program)),

                  const SizedBox(height: 24),

                  // Distribution note
                  Text(
                    'Geographic Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'The map shows the ${selectedFilter.toLowerCase()} beneficiary distribution across Quezon Province municipalities. Darker shades indicate higher beneficiary counts.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // New: Add method to build programs data table
  Widget _buildProgramsDataTable(List<Map<String, dynamic>> programs) {
    // Calculate total beneficiaries for percentage calculation - FIX NULL SAFETY ISSUES
    final int totalBeneficiaries = categoryTotalBeneficiaries ??
        programs.fold<int>(0, (sum, program) {
          final beneficiaries = program['totalBeneficiaries'] as int? ?? 0;
          return sum + beneficiaries;
        });

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 300,
      columns: [
        DataColumn2(
          label: Text(
            'Program Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          size: ColumnSize.L,
        ),
        DataColumn2(
          label: Text(
            'Organization',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          size: ColumnSize.M,
        ),
        DataColumn2(
          label: Text(
            'Beneficiaries',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label: Text(
            '%',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          size: ColumnSize.S,
          numeric: true,
        ),
      ],
      rows: programs.map((program) {
        // Calculate percentage of total - FIX NULL SAFETY ISSUES
        final beneficiaries = program['totalBeneficiaries'] as int? ?? 0;
        final double percentage = totalBeneficiaries > 0
            ? (beneficiaries / totalBeneficiaries * 100)
            : 0.0;

        return DataRow2(
          cells: [
            DataCell(
              Text(
                program['programName'] ?? 'Unnamed',
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              Text(
                program['organizationName'] ?? 'Unknown',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              Text(
                _formatNumber(beneficiaries),
                style: TextStyle(
                  color: _getCategoryColor(selectedFilter),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            DataCell(
              Text(
                '${percentage.toStringAsFixed(1)}%',
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // New: Add method to build municipality distribution chart
  Widget _buildMunicipalDistributionChart(List<Map<String, dynamic>> programs) {
    // For this example, we'll create mock data showing top 5 municipalities
    // In a real implementation, you'd extract this data from your beneficiary counts

    // Aggregate beneficiary counts by municipality from programs
    Map<String, int> municipalityCounts = {};

    // Collect the municipality data from all programs
    for (var program in programs) {
      // This assumes each program has a field with municipality data
      // You'll need to adapt this to your actual data structure
      if (program.containsKey('municipalityData')) {
        final munData = program['municipalityData'] as Map<String, int>;

        munData.forEach((municipality, count) {
          municipalityCounts[municipality] =
              (municipalityCounts[municipality] ?? 0) + count;
        });
      }
    }

    // Sort municipalities by beneficiary count and take top 5
    final sortedMunicipalities = municipalityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sortedMunicipalities.take(5).toList();

    // If we don't have actual municipality data, create placeholder data
    if (top5.isEmpty) {
      // Create placeholder data - you should replace this with actual data
      top5.addAll([
        MapEntry('Lucena City', 4500),
        MapEntry('Tayabas City', 3200),
        MapEntry('Sariaya', 2800),
        MapEntry('Candelaria', 2100),
        MapEntry('Tiaong', 1800),
      ]);
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: top5.isEmpty ? 5000 : (top5.first.value * 1.2), // 20% headroom
        barGroups: List.generate(
          top5.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: top5[index].value.toDouble(),
                color: _getCategoryColor(selectedFilter),
                width: 22,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= top5.length) return SizedBox.shrink();

                String name = top5[value.toInt()].key;
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
                    textAlign: TextAlign.center,
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
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: top5.isEmpty ? 1000 : top5.first.value / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildNoDataContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(selectedFilter),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${selectedFilter} Programs Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no active ${selectedFilter.toLowerCase()} programs with beneficiary data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Social':
        return Icons.people;
      case 'Educational':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Healthcare':
        return Colors.red.shade600;
      case 'Social':
        return Colors.green.shade600;
      case 'Educational':
        return Colors.blue.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  Widget _buildTotalBeneficiariesCard(String category) {
    final Color categoryColor = _getCategoryColor(category);
    final IconData categoryIcon = _getCategoryIcon(category);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon,
                size: 28,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total ${category} Beneficiaries',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoryTotalBeneficiaries != null
                        ? _formatNumber(categoryTotalBeneficiaries!)
                        : 'Loading...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> programData) {
    final String programName = programData['programName'] ?? 'Unnamed Program';
    final int beneficiaryCount = programData['totalBeneficiaries'] ?? 0;
    final String organizationName =
        programData['organizationName'] ?? 'Unknown Organization';
    final String? organizationLogo = programData['organizationLogo'];
    final Color categoryColor = _getCategoryColor(selectedFilter);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program name and organization
            Row(
              children: [
                // Organization logo or placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: organizationLogo != null && organizationLogo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            organizationLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.business,
                                  color: Colors.grey[400]);
                            },
                          ),
                        )
                      : Icon(Icons.business, color: Colors.grey[400]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        programName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'by $organizationName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Beneficiary count indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Beneficiaries',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _calculateProgressValue(beneficiaryCount),
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(categoryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatNumber(beneficiaryCount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to calculate progress value based on beneficiary count
  double _calculateProgressValue(int count) {
    final int maxValue = categoryTotalBeneficiaries ?? 100000;
    if (maxValue <= 0) return 0.0;
    return (count / maxValue).clamp(0.05, 1.0); // Ensure at least 5% visible
  }

  // Helper method to filter programs by category
  Future<List<Map<String, dynamic>>> _filterProgramsByCategory(
      List<QueryDocumentSnapshot> docs, String category) async {
    List<Map<String, dynamic>> result = [];
    print('Filtering ${docs.length} docs for category: $category');

    // First get program categories from Firestore
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] != 'beneficiaries') {
        print('Skipping document - not of type beneficiaries');
        continue;
      }

      final String programId = data['programId'] ?? '';
      if (programId.isEmpty) {
        print('Skipping document - no programId found');
        continue;
      }

      print('Processing programId: $programId');

      // Fetch program details to check category
      try {
        // Try both methods to get program details
        Map<String, dynamic>? programData = await _getProgramDetails(programId);

        // If first method failed, try the fallback method
        if (programData == null) {
          print('Using fallback method to find program: $programId');
          programData = await _getProgramDetailsFallback(programId);
        }

        if (programData != null) {
          final programCategory = programData['category'] ?? '';
          print(
              'Program category: $programCategory, target category: $category');

          // Make category matching more robust
          final normalizedCategory = programCategory.toLowerCase().trim();
          final targetCategory = category.toLowerCase().trim();

          bool matches = false;
          if (targetCategory == 'healthcare' &&
              normalizedCategory.contains('health')) {
            matches = true;
          } else if (targetCategory == 'social' &&
              (normalizedCategory.contains('social') ||
                  normalizedCategory.contains('welfare'))) {
            matches = true;
          } else if (targetCategory == 'educational' &&
              (normalizedCategory.contains('education') ||
                  normalizedCategory.contains('educational') ||
                  normalizedCategory.contains('school'))) {
            matches = true;
          }

          if (matches) {
            print('Match found! Program: ${programData['name']}');
            // Get the organization name
            final orgId = programData['organizationId'] ?? '';
            final orgData = await _getOrganizationDetails(orgId);

            // Add to results with enriched data
            result.add({
              'programId': programId,
              'programName': programData['name'] ?? 'Unnamed Program',
              'totalBeneficiaries': data['Total Beneficiaries'] ?? 0,
              'organizationId': orgId,
              'organizationName': orgData?['name'] ?? 'Unknown Organization',
              'organizationLogo': orgData?['logoUrl'] ?? '',
            });
          } else {
            print('No category match found');
          }
        } else {
          print('No program data found for ID: $programId');
        }
      } catch (e) {
        print('Error fetching program details: $e');
      }
    }

    // Sort by beneficiary count (descending)
    result.sort((a, b) => (b['totalBeneficiaries'] as int)
        .compareTo(a['totalBeneficiaries'] as int));

    print('Filtered results count: ${result.length}');
    return result;
  }

  // Helper method to get program details
  Future<Map<String, dynamic>?> _getProgramDetails(String programId) async {
    try {
      print('Looking for program with ID: $programId');
      // First try the direct approach assuming we know the organization ID
      final programs = await FirebaseFirestore.instance
          .collectionGroup('programs')
          .where('id', isEqualTo: programId)
          .limit(1)
          .get();

      if (programs.docs.isNotEmpty) {
        print('Found program via collectionGroup');
        return programs.docs.first.data();
      }

      // If not found, return null
      print('Program not found via collectionGroup');
      return null;
    } catch (e) {
      print('Error getting program details: $e');
      return null;
    }
  }

  // Add a fallback method to find programs
  Future<Map<String, dynamic>?> _getProgramDetailsFallback(
      String programId) async {
    try {
      // Try scanning through all organizations
      final organizationsSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      for (var orgDoc in organizationsSnapshot.docs) {
        final programsSnapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgDoc.id)
            .collection('programs')
            .where('id', isEqualTo: programId)
            .limit(1)
            .get();

        if (programsSnapshot.docs.isNotEmpty) {
          print('Found program via manual search in org: ${orgDoc.id}');
          return programsSnapshot.docs.first.data();
        }
      }

      print('Program not found in any organization');
      return null;
    } catch (e) {
      print('Error in fallback program search: $e');
      return null;
    }
  }

  // Helper method to get organization details
  Future<Map<String, dynamic>?> _getOrganizationDetails(String orgId) async {
    if (orgId.isEmpty) return null;

    try {
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .get();

      if (orgDoc.exists) {
        print('Organization found: ${orgDoc.data()?['name']}');
        return orgDoc.data();
      }

      print('Organization not found: $orgId');
      return null;
    } catch (e) {
      print('Error getting organization details: $e');
      return null;
    }
  }

  // Helper method to format numbers with commas
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
