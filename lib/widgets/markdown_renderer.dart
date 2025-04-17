import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // If data is empty after stripping whitespace, show a message without the generate button
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

    // Custom style for markdown with improved readability
    final customStyle = styleSheet ??
        MarkdownStyleSheet(
          // More readable text with increased spacing but SMALLER font sizes
          h1: TextStyle(
              fontSize: 18, // Reduced from 22
              fontWeight: FontWeight.bold,
              color: Colors.blue[800]),
          h2: TextStyle(
              fontSize: 16, // Reduced from 20
              fontWeight: FontWeight.bold,
              color: Colors.blue[700]),
          h3: TextStyle(
              fontSize: 15, // Reduced from 18
              fontWeight: FontWeight.bold,
              color: Colors.blue[600]),
          h4: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold), // Reduced from 16
          p: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87), // Reduced from 16
          // Better list item formatting
          listBullet: TextStyle(
              fontSize: 14, color: Colors.blue[800]), // Reduced from 16
          blockSpacing: 12.0, // Reduced from 16.0
          listIndent: 20.0, // Reduced from 24.0
          // Table styling
          tableBody: TextStyle(fontSize: 13), // Reduced from 15
          tableHead: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold), // Reduced from 16
          tableBorder: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          tableColumnWidth: const IntrinsicColumnWidth(),
          tableCellsPadding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 3), // Reduced padding
          // Improved bold and italic styles
          strong: const TextStyle(fontWeight: FontWeight.bold),
          em: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[800]),
        );

    // Return the Markdown widget directly without the container wrapper
    return Markdown(
      data: data,
      styleSheet: customStyle,
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
}
