import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'api_keys.dart';

class AIInsightsService {
  // OpenAI API configuration - stored securely
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Generate data summary
  static Future<String> generateDataSummary({
    required Map<String, dynamic> populationData,
    required Map<String, Map<String, int>> categoryData,
    required int? totalPopulation,
    required Map<String, int?> categoryTotals,
  }) async {
    // Format data for the prompt
    String formattedData = _formatDataForPrompt(
      populationData: populationData,
      categoryData: categoryData,
      totalPopulation: totalPopulation,
      categoryTotals: categoryTotals,
    );

    String prompt = '''
Generate a simple, easy-to-read summary of welfare distribution in Quezon Province for citizens based on the following data:
$formattedData

Make this summary specifically for the citizens of Quezon Province who want to understand their local welfare programs.
Use simple language and explain what this data means for average residents.
Format the response in clear sections:
1. A simple introduction about welfare programs in Quezon (2-3 sentences)
2. Population overview with key numbers in simple terms
3. Beneficiary distribution by program category with percentages
4. Information about which municipalities have the best coverage
5. Brief explanation of what these numbers mean for citizens

For municipalities with data, I specifically want to see organized information in a TABLE format.
Create proper tables with the following format:
| Municipality | Population | Percentage |
| --- | --- | --- |
| Lucena City | 278,924 | 14.3% |
| Sariaya | 161,868 | 8.3% |
(And so on for top municipalities)

You may use:
- Basic headings with # and ##
- Simple bullet points with *
- Plain paragraphs
- Table format for municipality data (as shown above)
- **Bold** for important values and headers
- IMPORTANT: Use plain ASCII characters only - no special quotes, dashes, or symbols
''';

    try {
      return await _makeOpenAIRequest(prompt);
    } catch (e) {
      return "Error generating data summary: $e";
    }
  }

  // Generate insights
  static Future<String> generateInsights({
    required Map<String, dynamic> populationData,
    required Map<String, Map<String, int>> categoryData,
    required int? totalPopulation,
    required Map<String, int?> categoryTotals,
  }) async {
    // Format data for the prompt
    String formattedData = _formatDataForPrompt(
      populationData: populationData,
      categoryData: categoryData,
      totalPopulation: totalPopulation,
      categoryTotals: categoryTotals,
    );

    String prompt = '''
Analyze the welfare distribution in Quezon Province based on this data and provide helpful insights and recommendations specifically for citizens:
$formattedData

This analysis is for the citizens of Quezon Province who want to understand welfare programs in their area and what they can do.
Use simple language anyone can understand. Focus on practical information.

Format your response in clear sections:
1. Key welfare program information that citizens should know
2. Areas with strong coverage and areas that need more support
3. Which welfare programs are most accessible in which areas
4. PRACTICAL ACTIONS citizens can take:
   - How to check eligibility for these programs
   - Where to apply for these programs
   - What documents might be needed
   - How to advocate for better coverage in underserved areas
5. Resources and contact information (use placeholder contact info if not provided)

For municipalities with data, I specifically want to see organized information in a TABLE format.
Create proper tables with the following format:
| Municipality | Healthcare | Social | Educational |
| --- | --- | --- | --- |
| Lucena City | 12,345 | 23,456 | 7,890 |
| Sariaya | 5,678 | 8,901 | 3,456 |
(And so on for top municipalities)

You may use:
- Basic headings with # and ##
- Simple bullet points with *
- Plain paragraphs 
- Table format for municipality data (as shown above)
- **Bold** for important values and headers
- IMPORTANT: Use plain ASCII characters only - no special quotes, dashes, or symbols
''';

    try {
      return await _makeOpenAIRequest(prompt);
    } catch (e) {
      return "Error generating insights: $e";
    }
  }

  // Helper method to format data for the prompt
  static String _formatDataForPrompt({
    required Map<String, dynamic> populationData,
    required Map<String, Map<String, int>> categoryData,
    required int? totalPopulation,
    required Map<String, int?> categoryTotals,
  }) {
    StringBuffer buffer = StringBuffer();

    // Total population
    buffer.writeln('Total Population: ${totalPopulation ?? "Unknown"}');
    buffer.writeln();

    // Category totals
    buffer.writeln('Beneficiary Totals:');
    categoryTotals.forEach((category, total) {
      buffer.writeln('- $category: ${total ?? "Unknown"}');
    });
    buffer.writeln();

    // Top 5 municipalities by population
    buffer.writeln('Top 5 Municipalities by Population:');
    var sortedByPopulation = populationData.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    for (int i = 0; i < 5 && i < sortedByPopulation.length; i++) {
      var entry = sortedByPopulation[i];
      buffer.writeln('- ${entry.key}: ${entry.value}');
    }
    buffer.writeln();

    // Sample municipality data for each category
    buffer.writeln('Sample Municipality Data by Category:');
    categoryData.forEach((category, municipalities) {
      buffer.writeln('$category:');
      var sortedMunicipalities = municipalities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (int i = 0; i < 3 && i < sortedMunicipalities.length; i++) {
        var entry = sortedMunicipalities[i];
        buffer.writeln('  - ${entry.key}: ${entry.value}');
      }
    });

    return buffer.toString();
  }

  // Make the API call to OpenAI - FIXED VERSION
  static Future<String> _makeOpenAIRequest(String prompt) async {
    // Get API key from secure storage
    final apiKey = APIKeys.getOpenAIKey();

    try {
      // Print the request we're about to make
      debugPrint(
          'Making API request to OpenAI with prompt length: ${prompt.length}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept-Charset': 'utf-8', // Explicitly request UTF-8
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'o4-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a data analyst who explains complex data in very simple terms. Your responses should be understandable by anyone, including those without technical knowledge.'
            },
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Check if content is empty
        if (content == null || content.isEmpty) {
          debugPrint('API returned empty content');
          return "No content was generated by the AI. Please try again.";
        }

        debugPrint(
            'Successfully received API response with content length: ${content.length}');

        // Process the markdown to ensure it's simple and compatible
        final processedContent = _processMarkdown(content);
        return processedContent;
      } else {
        // Include response body in error for debugging
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return "Error: Unable to generate content. Please try again later.";
      }
    } catch (e) {
      debugPrint('Exception in API call: $e');
      return "Error connecting to AI service. Please check your connection and try again.";
    }
  }

  // Helper to process and clean up markdown - ENHANCED VERSION
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

  // Comment out this entire method to ensure it's never used accidentally
  /*
  static String _convertMarkdownTablesToLists(String markdown) {
    // This method is completely disabled to preserve tables
    return markdown;
  }
  */

  // Helper to parse a table row into cells
  static List<String> _parseTableRow(String line) {
    final cells = line
        .split('|')
        .where((cell) => cell.isNotEmpty) // Remove empty cells from start/end
        .map((cell) => cell.trim()) // Trim whitespace
        .toList();
    return cells;
  }
}
