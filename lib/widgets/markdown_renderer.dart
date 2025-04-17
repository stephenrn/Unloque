import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';

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

    // Parse the content to identify tables and text blocks
    final segments = _parseContent(data);

    debugPrint('PARSED ${segments.length} CONTENT SEGMENTS');

    // Single section, no tables found - use standard markdown
    if (segments.length == 1 && segments.first.type == SegmentType.text) {
      return Markdown(
        data: data,
        styleSheet: styleSheet ?? _getDefaultStyleSheet(),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
          }
        },
        selectable: true,
      );
    }

    // Multiple segments - build custom layout with tables
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((segment) {
          if (segment.type == SegmentType.text) {
            // Render regular text with Markdown
            return Markdown(
              data: segment.content,
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
            );
          } else {
            // Render table with custom widget
            return _buildTableWidget(segment.content, context);
          }
        }).toList(),
      ),
    );
  }

  // Parse content into text and table segments
  List<ContentSegment> _parseContent(String content) {
    final List<ContentSegment> segments = [];
    final List<String> lines = content.split('\n');

    int currentPos = 0;
    int i = 0;

    while (i < lines.length) {
      // Look for the start of a table
      if (_isTableHeader(lines, i)) {
        // Add preceding text if any
        if (currentPos < i) {
          final textContent = lines.sublist(currentPos, i).join('\n');
          segments.add(ContentSegment(SegmentType.text, textContent));
        }

        // Extract the table
        final tableStart = i;
        i++; // Skip header line

        // Skip separator line
        if (i < lines.length && _isTableSeparator(lines[i])) {
          i++;

          // Read table rows
          while (i < lines.length &&
              lines[i].trim().startsWith('|') &&
              lines[i].trim().endsWith('|')) {
            i++;
          }

          // Extract the table content
          final tableContent = lines.sublist(tableStart, i).join('\n');
          segments.add(ContentSegment(SegmentType.table, tableContent));
          currentPos = i;
        } else {
          // Not a valid table, continue
          i++;
        }
      } else {
        // Not a table, continue
        i++;
      }
    }

    // Add remaining text
    if (currentPos < lines.length) {
      final textContent = lines.sublist(currentPos).join('\n');
      segments.add(ContentSegment(SegmentType.text, textContent));
    }

    return segments;
  }

  // Check if a line is a valid table header
  bool _isTableHeader(List<String> lines, int index) {
    if (index >= lines.length ||
        !lines[index].trim().startsWith('|') ||
        !lines[index].trim().endsWith('|')) {
      return false;
    }

    // Check if next line is a separator
    if (index + 1 >= lines.length) {
      return false;
    }

    final nextLine = lines[index + 1].trim();
    return _isTableSeparator(nextLine);
  }

  // Check if a line is a table separator
  bool _isTableSeparator(String line) {
    if (!line.startsWith('|') || !line.endsWith('|')) {
      return false;
    }

    // Remove pipes
    final content = line.substring(1, line.length - 1);
    // Check if it only contains dashes, colons, and spaces
    return RegExp(r'^[\s\-:]+$').hasMatch(content) && content.contains('-');
  }

  // Build a native Flutter Table widget
  Widget _buildTableWidget(String tableContent, BuildContext context) {
    debugPrint(
        'BUILDING NATIVE TABLE WIDGET FOR: ${tableContent.substring(0, min(50, tableContent.length))}...');

    // Parse table
    final List<String> lines = tableContent.split('\n');
    if (lines.length < 3) {
      return const SizedBox(); // Empty table
    }

    // Extract header and rows
    final List<String> headerCells = _parseTableRow(lines[0]);
    final List<List<String>> rows = [];

    for (int i = 2; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) {
        rows.add(_parseTableRow(lines[i]));
      }
    }

    debugPrint(
        'TABLE HAS ${headerCells.length} COLUMNS AND ${rows.length} ROWS');

    // Create table widget
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Table header
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: headerCells.map((cell) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    width: _calculateColumnWidth(cell),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      cell,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Table rows
            ...rows.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final row = entry.value;

              return Container(
                decoration: BoxDecoration(
                  color: rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: row.asMap().entries.map((cellEntry) {
                    final colIndex = cellEntry.key;
                    final cell = cellEntry.value;

                    return Container(
                      padding: EdgeInsets.all(12),
                      width: colIndex < headerCells.length
                          ? _calculateColumnWidth(headerCells[colIndex])
                          : 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        cell,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Parse table row into cells
  List<String> _parseTableRow(String line) {
    line = line.trim();
    if (line.startsWith('|')) line = line.substring(1);
    if (line.endsWith('|')) line = line.substring(0, line.length - 1);

    return line.split('|').map((cell) => cell.trim()).toList();
  }

  // Calculate column width based on content
  double _calculateColumnWidth(String content) {
    // Base width + character count to ensure columns with more text are wider
    return 100.0 + (content.length * 4.0).clamp(0.0, 100.0);
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

// Helper class for content segmentation
enum SegmentType { text, table }

class ContentSegment {
  final SegmentType type;
  final String content;

  ContentSegment(this.type, this.content);
}

// Helper function to get minimum of two numbers
int min(int a, int b) => a < b ? a : b;
