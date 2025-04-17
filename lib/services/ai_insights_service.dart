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
      // Validate input data
      if (populationData.isEmpty || categoryData.isEmpty) {
        debugPrint('Warning: Empty data provided to generateDataSummary');
        return 'Insufficient data available for analysis.';
      }

      // Format population data
      final formattedPopData = _formatPopulationData(populationData);
      debugPrint(
          'Population data formatted successfully. Length: ${formattedPopData.length}');

      // Format category data
      final formattedCategoryData =
          _formatCategoryData(categoryData, categoryTotals);
      debugPrint(
          'Category data formatted successfully. Length: ${formattedCategoryData.length}');

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
5. Explain how this data is important for citizens and how it affects their daily lives and access to services

DO NOT include any contact information, email addresses, phone numbers, or specific points of contact.
Do not make up or suggest any contact details, as these would be inaccurate.
Keep the analysis factual and data-driven. Format tables properly with clear headers and alignment.
''';

      // Check prompt length to avoid token limits
      if (dataPrompt.length > 4000) {
        debugPrint(
            'Warning: Prompt length exceeds 4000 chars: ${dataPrompt.length}');
        // Truncate data if necessary while preserving structure
        return _makeAPIRequestWithDataSafeguards(dataPrompt);
      }

      // Make the API call with improved error handling
      final response = await _makeAPIRequest(dataPrompt);
      return _processMarkdown(response);
    } catch (e) {
      debugPrint('Error generating data summary: $e');
      return 'Error generating data summary: ${e.toString()}. Please check your data and try again.';
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
      // Validate input data
      if (populationData.isEmpty || categoryData.isEmpty) {
        debugPrint('Warning: Empty data provided to generateInsights');
        return 'Insufficient data available for analysis.';
      }

      // Format population data
      final formattedPopData = _formatPopulationData(populationData);
      debugPrint(
          'Population data formatted successfully. Length: ${formattedPopData.length}');

      // Format category data
      final formattedCategoryData =
          _formatCategoryData(categoryData, categoryTotals);
      debugPrint(
          'Category data formatted successfully. Length: ${formattedCategoryData.length}');

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
5. Explain specific actions citizens can take to improve their access to programs, advocate for better services, or help their communities based on this data

IMPORTANT: When identifying underserved municipalities, provide specific numbers for healthcare, social, and educational coverage. Do not show zeros or dashes - instead show the actual numbers even if they are low or zero, and explain what those low numbers mean for citizens. Use percentages of coverage relative to population where possible.

DO NOT include any contact information, email addresses, phone numbers, or personal recommendations.
Do not suggest contacting specific offices, as contact details would be inaccurate.
Keep your response factual and objective. Format tables properly with clear headers and alignment.
''';

      // Check prompt length to avoid token limits
      if (insightsPrompt.length > 4000) {
        debugPrint(
            'Warning: Prompt length exceeds 4000 chars: ${insightsPrompt.length}');
        // Truncate data if necessary while preserving structure
        return _makeAPIRequestWithDataSafeguards(insightsPrompt);
      }

      // Make the API call with improved error handling
      final response = await _makeAPIRequest(insightsPrompt);
      return _processMarkdown(response);
    } catch (e) {
      debugPrint('Error generating insights: $e');
      return 'Error generating insights: ${e.toString()}. Please check your data and try again.';
    }
  }

  // Helper function to safely make API requests with large data
  static Future<String> _makeAPIRequestWithDataSafeguards(String prompt) async {
    // Create a simplified version of the prompt by reducing the data samples
    final lines = prompt.split('\n');
    final simplifiedLines = <String>[];
    bool inTable = false;
    int tableRows = 0;
    final int maxTableRows = 8; // Max rows to keep per table

    for (final line in lines) {
      // Detect table start/end
      if (line.contains('|') && line.contains('---')) {
        inTable = true;
        tableRows = 0;
        simplifiedLines.add(line);
      } else if (inTable && line.contains('|')) {
        tableRows++;
        if (tableRows <= maxTableRows) {
          simplifiedLines.add(line);
        }
      } else if (inTable && !line.contains('|')) {
        // Table ended
        inTable = false;
        if (tableRows > maxTableRows) {
          simplifiedLines.add("| ... (additional rows omitted) |");
        }
        simplifiedLines.add(line);
      } else {
        simplifiedLines.add(line);
      }
    }

    final simplifiedPrompt = simplifiedLines.join('\n');
    debugPrint(
        'Created simplified prompt with length: ${simplifiedPrompt.length}');

    // Make API call with simplified data
    return await _makeAPIRequest(simplifiedPrompt);
  }

  // Helper to format population data with better error checking
  static String _formatPopulationData(Map<String, dynamic> populationData) {
    StringBuffer buffer = StringBuffer();

    try {
      // Debug the incoming data
      debugPrint('Formatting population data:');
      debugPrint(
          '- Total Population key exists: ${populationData.containsKey('Total Population')}');

      // Make sure we're working with valid data
      if (populationData.isEmpty) {
        return "No population data available.";
      }

      // Make sure total population is included at the top
      int? totalPop = populationData['Total Population'] is num
          ? (populationData['Total Population'] as num).toInt()
          : null;

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

        if (sum > 0) {
          buffer.writeln(
              "Estimated Total Province Population: ${_formatNumber(sum)}");
          totalPop = sum; // Use this as the total for percentage calculations
        } else {
          buffer.writeln("Population data available but cannot be summed.");
          return buffer.toString();
        }
      }
      buffer.writeln("");

      buffer.writeln("| Municipality | Population | Percentage |");
      buffer.writeln("| --- | --- | --- |");

      // Calculate percentages and sort by population
      List<MapEntry<String, dynamic>> sortedEntries = populationData.entries
          .where((e) => e.key != 'Total Population' && e.value is num)
          .toList();

      if (sortedEntries.isEmpty) {
        buffer.writeln("| No municipality data available | N/A | N/A |");
        return buffer.toString();
      }

      sortedEntries.sort((a, b) => (b.value as num).compareTo(a.value as num));

      // Take top municipalities by population (limit to prevent token issues)
      final topEntries = sortedEntries.take(10);

      for (var entry in topEntries) {
        final percentage = totalPop > 0
            ? ((entry.value / totalPop) * 100).toStringAsFixed(1) + '%'
            : 'N/A';

        buffer.writeln(
            "| ${entry.key} | ${_formatNumber(entry.value)} | $percentage |");
      }

      // If there are more entries, indicate that they're omitted
      if (sortedEntries.length > 10) {
        buffer.writeln("| ... (remaining municipalities omitted) | | |");
      }
    } catch (e) {
      debugPrint('Error formatting population data: $e');
      buffer.writeln("| Error formatting population data | N/A | N/A |");
    }

    return buffer.toString();
  }

  // Helper to format category data with better error checking
  static String _formatCategoryData(Map<String, Map<String, int>> categoryData,
      Map<String, int?>? categoryTotals) {
    StringBuffer buffer = StringBuffer();

    try {
      // Debug the incoming data
      debugPrint('Formatting category data:');
      debugPrint('- Categories: ${categoryData.keys.join(', ')}');

      if (categoryData.isEmpty) {
        return "No category data available.";
      }

      // First write a summary of the category totals
      if (categoryTotals != null && categoryTotals.isNotEmpty) {
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

      // Check if we have actual program data
      bool hasData = false;
      categoryData.forEach((category, data) {
        if (data.isNotEmpty) hasData = true;
      });

      if (!hasData) {
        buffer.writeln(
            "No detailed welfare program data available by municipality.");
        return buffer.toString();
      }

      // Now create a consolidated table for top municipalities
      buffer.writeln("### Welfare Program Coverage by Municipality");
      buffer.writeln(
          "| Municipality | Healthcare | Social | Educational | Population Coverage Ratio |");
      buffer.writeln(
          "| -------------- | ---------- | ------ | ----------- | ----------------------- |");

      // Find municipalities with highest total beneficiaries
      Map<String, int> municipalityTotals = {};
      Map<String, int> municipalityPopulation = {};

      // First get all municipality names
      Set<String> allMunicipalities = {};
      categoryData.forEach((category, data) {
        allMunicipalities.addAll(data.keys);
      });

      if (allMunicipalities.isEmpty) {
        buffer.writeln(
            "| No municipality data available | N/A | N/A | N/A | N/A |");
        return buffer.toString();
      }

      // Calculate totals and include some underserved municipalities
      for (String municipality in allMunicipalities) {
        int total = 0;
        categoryData.forEach((category, data) {
          total += data[municipality] ?? 0;
        });
        municipalityTotals[municipality] = total;
      }

      // Include both high-coverage and underserved municipalities
      List<String> sortedByTotal = municipalityTotals.keys.toList()
        ..sort(
            (a, b) => municipalityTotals[b]!.compareTo(municipalityTotals[a]!));

      // Take top municipalities by coverage (limit to prevent token issues)
      final topMunicipalities = sortedByTotal.take(8);

      // Find potentially underserved municipalities (low coverage but might have population)
      final underservedMunicipalities = sortedByTotal.reversed.take(3).toList();

      // Combine both lists for display, removing duplicates
      final Set<String> municipalitiesToShow = {
        ...topMunicipalities,
        ...underservedMunicipalities
      };

      // Build the table
      for (String municipality in municipalitiesToShow) {
        final healthcare = categoryData['Healthcare']?[municipality] != null
            ? _formatNumber(categoryData['Healthcare']![municipality]!)
            : '0'; // Changed from 'N/A' to '0' to be more clear

        final social = categoryData['Social']?[municipality] != null
            ? _formatNumber(categoryData['Social']![municipality]!)
            : '0'; // Changed from 'N/A' to '0'

        final educational = categoryData['Educational']?[municipality] != null
            ? _formatNumber(categoryData['Educational']![municipality]!)
            : '0'; // Changed from 'N/A' to '0'

        // Calculate ratio or coverage indicator
        final totalBeneficiaries = municipalityTotals[municipality] ?? 0;
        final coverageIndicator = (totalBeneficiaries == 0)
            ? "Underserved"
            : (totalBeneficiaries < 1000 ? "Low coverage" : "Standard");

        buffer.writeln(
            "| $municipality | $healthcare | $social | $educational | $coverageIndicator |");
      }

      // Add a special section for underserved municipalities
      buffer.writeln("\n### Potentially Underserved Municipalities");
      buffer.writeln(
          "| Municipality | Healthcare | Social | Educational | Note |");
      buffer.writeln(
          "| ------------ | ---------- | ------ | ----------- | ---- |");

      for (String municipality in underservedMunicipalities) {
        final healthcare = categoryData['Healthcare']?[municipality] ?? 0;
        final social = categoryData['Social']?[municipality] ?? 0;
        final educational = categoryData['Educational']?[municipality] ?? 0;

        buffer.writeln(
            "| $municipality | ${_formatNumber(healthcare)} | ${_formatNumber(social)} | ${_formatNumber(educational)} | May need additional resources |");
      }
    } catch (e) {
      debugPrint('Error formatting category data: $e');
      buffer.writeln("| Error formatting category data | N/A | N/A | N/A |");
    }

    return buffer.toString();
  }

  // Helper to format large numbers with commas
  static String _formatNumber(dynamic number) {
    if (number == null) return 'N/A';

    try {
      final int numValue = number is int ? number : number.toInt();
      return numValue.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    } catch (e) {
      debugPrint('Error formatting number: $e');
      return number.toString();
    }
  }

  // Helper to make API requests to OpenAI with improved error handling
  static Future<String> _makeAPIRequest(String prompt) async {
    try {
      // Debug length
      debugPrint(
          'Making API request to OpenAI with prompt length: ${prompt.length}');

      final apiKey = APIKeys.getOpenAIKey();

      if (apiKey.isEmpty) {
        throw Exception('API key is empty or invalid');
      }

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
                  'When reporting on underserved areas, always show specific numbers rather than zeros or dashes. '
                  'Even low numbers should be clearly displayed and analyzed for what they mean for citizens. '
                  'DO NOT include any contact information, email addresses, phone numbers, or personal references as these would be inaccurate. '
                  'Focus solely on data analysis and objective insights.'
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

        if (!data.containsKey('choices') ||
            data['choices'].isEmpty ||
            !data['choices'][0].containsKey('message') ||
            !data['choices'][0]['message'].containsKey('content')) {
          throw Exception('Unexpected response format from API');
        }

        String content = data['choices'][0]['message']['content'];
        debugPrint(
            'Successfully received API response with content length: ${content.length}');
        return content;
      } else {
        throw Exception(
            'API request failed with status code ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in API request: $e');
      return 'Error communicating with AI service: ${e.toString()}';
    }
  }

  // Helper to process and clean up markdown - REINSTATED CONTACT INFO FILTERING
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
      RegExp(r'contact\s+information', caseSensitive: false),
      RegExp(r'contact\s+details', caseSensitive: false),
    ];

    for (final pattern in contactPhrases) {
      text = text.replaceAll(pattern, "For more information");
    }

    return text;
  }
}
