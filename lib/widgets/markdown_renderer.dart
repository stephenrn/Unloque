import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // For HTML escaping and Unicode handling
import 'package:unloque/utils/markdown_content_parser.dart';

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
    final segments = MarkdownContentParser.parse(data);

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

  // Build a native Flutter Table widget
  Widget _buildTableWidget(String tableContent, BuildContext context) {
    debugPrint(
        'BUILDING NATIVE TABLE WIDGET FOR: ${tableContent.substring(0, MarkdownContentParser.minInt(50, tableContent.length))}...');

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

    // Enhanced parsing to handle potential issues
    return line.split('|').map((cell) {
      // Clean up cell content more thoroughly
      return _superSanitizeContent(cell.trim());
    }).toList();
  }

  // Add the missing method for calculating column width
  double _calculateColumnWidth(String content) {
    // Base width + character count to ensure columns with more text are wider
    return 100.0 + (content.length * 4.0).clamp(0.0, 100.0);
  }

  // Enhanced sanitization function with more comprehensive character handling
  String _superSanitizeContent(String content) {
    debugPrint('SANITIZING CONTENT: $content');

    // First pass - replace all common problematic characters
    String sanitized = content
        // Fix common encoding issues
        .replaceAll('â€™', "'") // Right single quotation mark
        .replaceAll('â€œ', '"') // Left double quotation mark
        .replaceAll('â€', '"') // Right double quotation mark
        .replaceAll('â€"', "–") // En dash
        .replaceAll('â€"', "—") // Em dash
        .replaceAll('â', "'") // Single quote
        .replaceAll('Â', "") // Non-breaking space
        .replaceAll('\u00A0', " ") // Another non-breaking space
        // Replace other common problematic characters
        .replaceAll('–', '-') // En dash to hyphen
        .replaceAll('—', '-') // Em dash to hyphen
        .replaceAll('…', '...') // Ellipsis to dots
        .replaceAll('•', '*') // Bullet to asterisk
        .replaceAll('·', '*') // Middle dot to asterisk
        .replaceAll('\'', "'") // Smart quote to regular quote
        .replaceAll('\'', "'") // Smart quote to regular quote
        .replaceAll('"', '"') // Smart quote to regular quote
        .replaceAll('"', '"') // Smart quote to regular quote
        .replaceAll('„', '"') // Double low-9 quotation mark
        .replaceAll('‹', '<') // Single left-pointing angle quotation
        .replaceAll('›', '>') // Single right-pointing angle quotation
        .replaceAll('«', '<<') // Left-pointing double angle quotation
        .replaceAll('»', '>>') // Right-pointing double angle quotation
        .replaceAll('±', '+/-') // Plus-minus sign
        .replaceAll('×', 'x') // Multiplication sign
        .replaceAll('÷', '/') // Division sign
        .replaceAll('≤', '<=') // Less-than or equal to
        .replaceAll('≥', '>=') // Greater-than or equal to
        .replaceAll('≠', '!=') // Not equal to
        .replaceAll('≈', '~=') // Almost equal to
        .replaceAll('∞', 'infinity') // Infinity
        .replaceAll('£', 'GBP ') // Pound
        .replaceAll('€', 'EUR ') // Euro
        .replaceAll('¥', 'JPY ') // Yen
        .replaceAll('©', '(c)') // Copyright
        .replaceAll('®', '(R)') // Registered trademark
        .replaceAll('™', '(TM)') // Trademark
        .replaceAll('\t', '    ') // Tab to spaces
        // Remove control characters
        .replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]'), '');

    // Special handling for Unicode surrogate pairs
    try {
      // Try to normalize the string - convert to well-formed UTF-8 text
      List<int> bytes = utf8.encode(sanitized);
      sanitized = utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      debugPrint('Error normalizing text: $e');
      // If normalization fails, do more aggressive character filtering
      sanitized = sanitized.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
    }

    // Escape HTML entities to prevent rendering issues
    sanitized = _escapeHTML(sanitized);

    return sanitized;
  }

  String _escapeHTML(String value) {
    return const HtmlEscape().convert(value);
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
