import 'package:flutter/material.dart';
import 'package:unloque/models/organization_response_section.dart';

class OrganizationResponseSections extends StatelessWidget {
  final List<ResponseSection> sections;

  /// If provided, shows a per-file spinner when `downloadingFiles[fileName]` is true.
  final Map<String, bool>? downloadingFiles;

  /// If provided, makes attachments tappable when `downloadUrl` is non-empty.
  final void Function(String downloadUrl, String fileName)? onAttachmentTap;

  /// If true, underlines attachment names even when not tappable.
  final bool underlineAllAttachments;

  const OrganizationResponseSections({
    super.key,
    required this.sections,
    this.downloadingFiles,
    this.onAttachmentTap,
    this.underlineAllAttachments = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final widgets = <Widget>[];
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];

      widgets.add(
        Text(
          section.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));

      if (section is ParagraphResponseSection) {
        widgets.add(
          Text(
            section.content,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        );
      } else if (section is ListResponseSection) {
        for (final item in section.items) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, left: 4, right: 8),
                    child: Icon(Icons.circle, size: 6, color: Colors.blue),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else if (section is AttachmentResponseSection) {
        if (section.files.isEmpty) {
          widgets.add(
            Text(
              'No attachments available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        } else {
          for (final fileData in section.files) {
            final fileName = fileData.name;
            final downloadUrl = fileData.downloadUrl;
            final isDownloading = downloadingFiles?[fileName] ?? false;
            final isTappable =
              onAttachmentTap != null && (downloadUrl?.isNotEmpty ?? false);

            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (isDownloading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.insert_drive_file,
                          size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: isTappable
                            ? () {
                                final url = downloadUrl;
                                if (url == null || url.isEmpty) return;
                                onAttachmentTap!(url, fileName);
                              }
                            : null,
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isTappable || underlineAllAttachments
                                ? Colors.blue
                                : Colors.grey,
                            decoration: (isTappable || underlineAllAttachments)
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }

      if (i < sections.length - 1) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(Divider(color: Colors.grey[300]));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
