import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert'; // Add this for base64 encoding

class MarkdownRenderer extends StatelessWidget {
  final String data;
  final bool isLoading;
  final String? errorMessage;
  final MarkdownStyleSheet? styleSheet;
  final VoidCallback? onRetry;

  const MarkdownRenderer({
    Key? key,
    required this.data,
    this.isLoading = false,
    this.errorMessage,
    this.styleSheet,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: [
          const SizedBox(height: 8),
          const Center(
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          const Text('Generating analysis...'),
        ],
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (data.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 36),
            SizedBox(height: 16),
            Text(
              'No data available yet. The content will load automatically.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // NEW APPROACH: Split and process content differently based on type
    final processedContent = _processContent(data);

    // Return a Column containing both HTML and Markdown widgets
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: processedContent,
      ),
    );
  }

  // New method that splits content and returns appropriate widgets
  List<Widget> _processContent(String rawContent) {
    debugPrint('PROCESSING CONTENT WITH NEW STRATEGY');

    // Split content into sections: text and tables
    List<Widget> contentWidgets = [];

    // Extract tables and their positions
    final tablePattern = RegExp(
        r'(\|[^\n]*\|\n\|[\s\-:]+\|[\s\-:]+\|[^\n]*\n(?:\|[^\n]*\|\n)*)',
        multiLine: true);

    // Find all tables in the content
    final matches = tablePattern.allMatches(rawContent);
    List<MapEntry<int, int>> tablePositions = [];

    for (final match in matches) {
      tablePositions.add(MapEntry(match.start, match.end));
      debugPrint('FOUND TABLE AT POSITIONS ${match.start}-${match.end}');
    }

    // If no tables, just use the standard Markdown widget
    if (tablePositions.isEmpty) {
      debugPrint('NO TABLES FOUND - USING STANDARD MARKDOWN');
      contentWidgets.add(
        Markdown(
          data: rawContent,
          styleSheet: styleSheet ?? _getDefaultStyleSheet(),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onTapLink: (text, href, title) {
            if (href != null) {
              launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
            }
          },
          selectable: true,
        ),
      );
      return contentWidgets;
    }

    // If there are tables, split content and process each section
    int currentPosition = 0;

    for (var tablePos in tablePositions) {
      int tableStart = tablePos.key;
      int tableEnd = tablePos.value;

      // Add text before the table as Markdown
      if (tableStart > currentPosition) {
        final textBefore = rawContent.substring(currentPosition, tableStart);
        if (textBefore.trim().isNotEmpty) {
          contentWidgets.add(
            Markdown(
              data: textBefore,
              styleSheet: styleSheet ?? _getDefaultStyleSheet(),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href),
                      mode: LaunchMode.externalApplication);
                }
              },
              selectable: true,
            ),
          );
        }
      }

      // Process the table as HTML
      final tableText = rawContent.substring(tableStart, tableEnd);
      final htmlTable = _convertTableToHTML(tableText);

      // Directly embed the HTML table using Html widget
      contentWidgets.add(
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Html(
              data: htmlTable,
              style: {
                'table': Style(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  backgroundColor: Colors.white,
                ),
                'th': Style(
                  backgroundColor: Colors.blue.shade50,
                  padding: HtmlPaddings.all(8),
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.bold,
                ),
                'td': Style(
                  padding: HtmlPaddings.all(8),
                  textAlign: TextAlign.center,
                ),
                'tr': Style(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
              },
            ),
          ),
        ),
      );

      currentPosition = tableEnd;
    }

    // Add any remaining text after the last table
    if (currentPosition < rawContent.length) {
      final textAfter = rawContent.substring(currentPosition);
      if (textAfter.trim().isNotEmpty) {
        contentWidgets.add(
          Markdown(
            data: textAfter,
            styleSheet: styleSheet ?? _getDefaultStyleSheet(),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href),
                    mode: LaunchMode.externalApplication);
              }
            },
            selectable: true,
          ),
        );
      }
    }

    return contentWidgets;
  }

  // Convert markdown table to clean HTML with enhanced CSS
  String _convertTableToHTML(String tableMarkdown) {
    debugPrint(
        'CONVERTING TABLE MARKDOWN TO HTML: ${tableMarkdown.substring(0, tableMarkdown.length > 50 ? 50 : tableMarkdown.length)}...');

    List<String> lines = tableMarkdown.trim().split('\n');
    if (lines.length < 3) {
      debugPrint('INVALID TABLE FORMAT: Less than 3 lines');
      return '<p><em>Invalid table format</em></p>';
    }

    // Extract header row and separator
    String headerLine = lines[0];
    String separatorLine = lines[1];

    // Validate table format
    if (!headerLine.contains('|') ||
        !separatorLine.contains('|') ||
        !separatorLine.contains('-')) {
      debugPrint('INVALID TABLE FORMAT: Missing separators');
      return '<p><em>Invalid table format</em></p>';
    }

    // Extract header cells
    List<String> headers = _parseTableRow(headerLine);

    // Extract data rows
    List<List<String>> rows = [];
    for (int i = 2; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty && lines[i].contains('|')) {
        rows.add(_parseTableRow(lines[i]));
      }
    }

    // Create HTML table with enhanced CSS
    StringBuffer html = StringBuffer();
    html.write('''
    <div style="width:100%; overflow-x:auto; margin:16px 0;">
      <table style="width:100%; border-collapse:collapse; border:2px solid #ddd; table-layout:fixed;">
        <thead>
          <tr style="background-color:#edf6ff;">
    ''');

    // Add header cells
    for (String header in headers) {
      html.write(
          '<th style="padding:12px; text-align:center; border:1px solid #ddd; font-weight:bold;">${_escapeHtml(header)}</th>');
    }

    html.write('''
          </tr>
        </thead>
        <tbody>
    ''');

    // Add data rows with alternating colors
    for (int i = 0; i < rows.length; i++) {
      String bgColor = i % 2 == 0 ? '#ffffff' : '#f8f9fa';
      html.write('<tr style="background-color:$bgColor;">');

      for (int j = 0; j < headers.length && j < rows[i].length; j++) {
        html.write(
            '<td style="padding:10px; text-align:center; border:1px solid #ddd;">${_escapeHtml(rows[i][j])}</td>');
      }

      html.write('</tr>');
    }

    html.write('''
        </tbody>
      </table>
    </div>
    ''');

    final result = html.toString();
    debugPrint(
        'GENERATED HTML TABLE: ${result.substring(0, result.length > 50 ? 50 : result.length)}...');

    return result;
  }

  // Parse table row into cells
  List<String> _parseTableRow(String line) {
    line = line.trim();
    if (line.startsWith('|')) line = line.substring(1);
    if (line.endsWith('|')) line = line.substring(0, line.length - 1);

    return line.split('|').map((cell) => cell.trim()).toList();
  }

  // Escape HTML special characters
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }

  // Get default style sheet for markdown
  MarkdownStyleSheet _getDefaultStyleSheet() {
    return MarkdownStyleSheet(
      h1: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
      h2: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700]),
      h3: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[600]),
      p: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
      listBullet: TextStyle(fontSize: 14, color: Colors.blue[800]),
      blockSpacing: 12.0,
      listIndent: 20.0,
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[800]),
    );
  }
}
