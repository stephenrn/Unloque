import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class AIInsightsService {
  // Generate data summary using AI
  static Future<String> generateDataSummary({
    required Map<String, dynamic> populationData,
    required Map<String, Map<String, int>> categoryData,
    int? totalPopulation,
    Map<String, int?>? categoryTotals,
  }) async {
    try {
      debugPrint('AI Service - Generating data summary');
      debugPrint('Population data received: ${populationData.length} items');
      debugPrint('Total population value: $totalPopulation');

      // Debug: check the populationData structure
      if (populationData['Total Population'] == null) {
        debugPrint('WARNING: Missing total population in population data');
        // Ensure total population exists in the data
        if (totalPopulation != null) {
          populationData = Map.from(populationData);
          populationData['Total Population'] = totalPopulation;
          debugPrint('Added total population from parameter: $totalPopulation');
        }
      }

      // Format population data
      final formattedPopData = _formatPopulationData(populationData);

      // Format category data
      final formattedCategoryData =
          _formatCategoryData(categoryData, categoryTotals);

      // Build the data prompt
      final dataPrompt = '''
# Population and Welfare Program Data

## Population Data:
$formattedPopData

## Welfare Program Data:
$formattedCategoryData

Please provide a clear, informative summary of this data in markdown format. Include:
1. Key statistics and trends in population distribution
2. Insights on program coverage across municipalities
3. Highlight areas with high/low coverage
4. Show relevant data in tables for clarity

DO NOT include any contact information, personal details, or recommendations to contact specific persons or offices.
Keep the analysis factual and data-driven. Format tables properly with clear headers and alignment.
''';

      // Make the API call
      final response = await _makeAPIRequest(dataPrompt);
      return _processMarkdown(response);
    } catch (e) {
      debugPrint('Error generating data summary: $e');
      return 'Error generating data summary. Please try again later.';
    }
  }

  // Generate AI insights
  static Future<String> generateInsights({
    required Map<String, dynamic> populationData,
    required Map<String, Map<String, int>> categoryData,
    int? totalPopulation,
    Map<String, int?>? categoryTotals,
  }) async {
    try {
      debugPrint('AI Service - Generating insights');
      debugPrint('Population data received: ${populationData.length} items');
      debugPrint('Total population value: $totalPopulation');

      // Debug: check the populationData structure
      if (populationData['Total Population'] == null) {
        debugPrint('WARNING: Missing total population in population data');
        // Ensure total population exists in the data
        if (totalPopulation != null) {
          populationData = Map.from(populationData);
          populationData['Total Population'] = totalPopulation;
          debugPrint('Added total population from parameter: $totalPopulation');
        }
      }

      // Format population data
      final formattedPopData = _formatPopulationData(populationData);

      // Format category data
      final formattedCategoryData =
          _formatCategoryData(categoryData, categoryTotals);

      // Build the insights prompt
      final insightsPrompt = '''
# Population and Welfare Program Data

## Population Data:
$formattedPopData

## Welfare Program Data:
$formattedCategoryData

Based on this data, provide strategic insights in markdown format:
1. Identify municipalities that are underserved in relation to their population
2. Suggest program types that could be expanded based on coverage gaps
3. Highlight successful distribution patterns
4. Identify opportunities for better resource allocation

DO NOT include any contact information, phone numbers, email addresses, or specific points of contact.
Keep your response factual and objective. Format tables properly with clear headers and alignment.
''';

      // Make the API call
      final response = await _makeAPIRequest(insightsPrompt);
      return _processMarkdown(response);
    } catch (e) {
      debugPrint('Error generating insights: $e');
      return 'Error generating insights. Please try again later.';
    }
  }

  // Helper to format population data
  static String _formatPopulationData(Map<String, dynamic> populationData) {
    StringBuffer buffer = StringBuffer();

    // Debug the incoming data
    debugPrint('Formatting population data:');
    debugPrint(
        '- Total Population key exists: ${populationData.containsKey('Total Population')}');
    if (populationData.containsKey('Total Population')) {
      debugPrint(
          '- Total Population value: ${populationData['Total Population']}');
    } else {
      debugPrint(
          '- Keys in population data: ${populationData.keys.join(', ')}');
    }

    // Make sure total population is included at the top
    int? totalPop = populationData['Total Population'] as int?;
    if (totalPop != null) {
      buffer.writeln("Total Province Population: ${_formatNumber(totalPop)}");
    } else {
      // If not available, sum all municipalities
      int sum = 0;
      populationData.forEach((key, value) {
        if (key != 'Total Population' && value is num) {
          sum += value.toInt();
        }
      });
      buffer.writeln(
          "Estimated Total Province Population: ${_formatNumber(sum)}");
      totalPop = sum; // Use this as the total for percentage calculations
    }
    buffer.writeln("");

    buffer.writeln("| Municipality | Population | Percentage |");
    buffer.writeln("| --- | --- | --- |");

    // Calculate percentages and sort by population
    List<MapEntry<String, dynamic>> sortedEntries = populationData.entries
        .where((e) => e.key != 'Total Population' && e.value is num)
        .toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    // Take top municipalities by population
    final topEntries = sortedEntries.take(15);

    for (var entry in topEntries) {
      final percentage = totalPop > 0
          ? ((entry.value / totalPop) * 100).toStringAsFixed(1) + '%'
          : 'N/A';

      buffer.writeln(
          "| ${entry.key} | ${_formatNumber(entry.value)} | $percentage |");
    }

    return buffer.toString();
  }

  // Helper to format category data
  static String _formatCategoryData(Map<String, Map<String, int>> categoryData,
      Map<String, int?>? categoryTotals) {
    StringBuffer buffer = StringBuffer();

    // Debug the incoming data
    debugPrint('Formatting category data:');
    debugPrint('- Categories: ${categoryData.keys.join(', ')}');
    if (categoryTotals != null) {
      debugPrint(
          '- Category totals provided: ${categoryTotals.keys.join(', ')}');
    }

    // First write a summary of the category totals
    if (categoryTotals != null) {
      buffer.writeln("### Program Category Totals");
      buffer.writeln("| Category | Beneficiaries |");
      buffer.writeln("| --- | --- |");

      categoryTotals.forEach((category, total) {
        if (total != null && category != 'Total Population') {
          buffer.writeln("| $category | ${_formatNumber(total)} |");
        }
      });
      buffer.writeln("");
    }

    // Now create a consolidated table for top municipalities
    buffer.writeln("### Welfare Program Coverage by Municipality");
    buffer.writeln("| Municipality | Healthcare | Social | Educational |");
    buffer.writeln("| -------------- | ---------- | ------ | ----------- |");

    // Find municipalities with highest total beneficiaries
    Map<String, int> municipalityTotals = {};

    // First get all municipality names
    Set<String> allMunicipalities = {};
    categoryData.forEach((category, data) {
      allMunicipalities.addAll(data.keys);
    });

    debugPrint('- Found ${allMunicipalities.length} unique municipalities');

    // Calculate totals
    for (String municipality in allMunicipalities) {
      int total = 0;
      categoryData.forEach((category, data) {
        total += data[municipality] ?? 0;
      });
      municipalityTotals[municipality] = total;
    }

    // Sort municipalities by total beneficiaries
    List<String> sortedMunicipalities = municipalityTotals.keys.toList()
      ..sort(
          (a, b) => municipalityTotals[b]!.compareTo(municipalityTotals[a]!));

    // Take top municipalities
    final topMunicipalities = sortedMunicipalities.take(15);

    // Build the table
    for (String municipality in topMunicipalities) {
      final healthcare = categoryData['Healthcare']?[municipality] != null
          ? _formatNumber(categoryData['Healthcare']![municipality]!)
          : 'N/A';

      final social = categoryData['Social']?[municipality] != null
          ? _formatNumber(categoryData['Social']![municipality]!)
          : 'N/A';

      final educational = categoryData['Educational']?[municipality] != null
          ? _formatNumber(categoryData['Educational']![municipality]!)
          : 'N/A';

      buffer
          .writeln("| $municipality | $healthcare | $social | $educational |");
    }

    return buffer.toString();
  }

  // Helper to format large numbers with commas
  static String _formatNumber(dynamic number) {
    if (number == null) return 'N/A';

    final int numValue = number is int ? number : number.toInt();
    return numValue.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // Helper to make API requests to OpenAI
  static Future<String> _makeAPIRequest(String prompt) async {
    // Debug length
    debugPrint(
        'Making API request to OpenAI with prompt length: ${prompt.length}');

    final apiKey = APIKeys.getOpenAIKey();
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a data analyst specializing in population statistics and welfare program distribution. '
                'Provide clear, concise, and factual analysis with properly formatted markdown tables. '
                'Do NOT include any contact information, email addresses, phone numbers, or personal references.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.5,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      String content = data['choices'][0]['message']['content'];
      debugPrint(
          'Successfully received API response with content length: ${content.length}');
      return content;
    } else {
      throw Exception(
          'Failed to get response: ${response.statusCode} ${response.body}');
    }
  }

  // Helper to process and clean up markdown
  static String _processMarkdown(String markdown) {
    // Replace complex markdown elements with simpler ones if necessary
    String processed = markdown;

    // Fix common encoding issues
    processed = processed
        .replaceAll('â€™', "'") // Right single quotation mark
        .replaceAll('â€œ', '"') // Left double quotation mark
        .replaceAll('â€', '"') // Right double quotation mark
        .replaceAll('â€"', "–") // En dash
        .replaceAll('â€"', "—") // Em dash
        .replaceAll('â', "'") // Single quote
        .replaceAll('Â', "") // Non-breaking space
        .replaceAll('\u00A0', " "); // Another non-breaking space

    // CRITICAL: Completely disable table conversion to maintain table structure
    // processed = _convertMarkdownTablesToLists(processed);

    // Remove any contact information that might have slipped through
    processed = _removeContactInfo(processed);

    // Log the first table found for debugging
    if (processed.contains('|')) {
      final tableLines =
          processed.split('\n').where((line) => line.contains('|')).take(5);
      if (tableLines.isNotEmpty) {
        debugPrint('MARKDOWN CONTAINS TABLES. First 5 lines of first table:');
        for (var line in tableLines) {
          debugPrint('TABLE LINE: $line');
        }
      }
    }

    return processed;
  }

  // Method to remove any contact information
  static String _removeContactInfo(String text) {
    // Remove email addresses
    final emailPattern = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,}\b');
    text = text.replaceAll(emailPattern, "[EMAIL REMOVED]");

    // Remove phone numbers - various formats
    final phonePatterns = [
      RegExp(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b'), // 555-555-5555
      RegExp(r'\b\(\d{3}\)\s*\d{3}[-.\s]?\d{4}\b'), // (555) 555-5555
      RegExp(
          r'\b\+\d{1,3}[-.\s]?\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b'), // +1 555-555-5555
    ];

    for (final pattern in phonePatterns) {
      text = text.replaceAll(pattern, "[PHONE REMOVED]");
    }

    // Remove phrases like "contact us at" or "reach out to"
    final contactPhrases = [
      RegExp(r'contact\s+\w+\s+at', caseSensitive: false),
      RegExp(r'reach\s+out\s+to', caseSensitive: false),
      RegExp(r'call\s+\w+\s+at', caseSensitive: false),
      RegExp(r'email\s+\w+\s+at', caseSensitive: false),
    ];

    for (final pattern in contactPhrases) {
      text = text.replaceAll(pattern, "contact");
    }

    return text;
  }
}
