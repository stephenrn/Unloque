enum SegmentType { text, table }

class ContentSegment {
  final SegmentType type;
  final String content;

  ContentSegment(this.type, this.content);
}

class MarkdownContentParser {
  static List<ContentSegment> parse(String content) {
    final List<ContentSegment> segments = [];
    final List<String> lines = content.split('\n');

    int currentPos = 0;
    int i = 0;

    while (i < lines.length) {
      if (_isTableHeader(lines, i)) {
        if (currentPos < i) {
          final textContent = lines.sublist(currentPos, i).join('\n');
          segments.add(ContentSegment(SegmentType.text, textContent));
        }

        final tableStart = i;
        i++;

        if (i < lines.length && _isTableSeparator(lines[i].trim())) {
          i++;

          while (i < lines.length &&
              lines[i].trim().startsWith('|') &&
              lines[i].trim().endsWith('|')) {
            i++;
          }

          final tableContent = lines.sublist(tableStart, i).join('\n');
          segments.add(ContentSegment(SegmentType.table, tableContent));
          currentPos = i;
        } else {
          i++;
        }
      } else {
        i++;
      }
    }

    if (currentPos < lines.length) {
      final textContent = lines.sublist(currentPos).join('\n');
      segments.add(ContentSegment(SegmentType.text, textContent));
    }

    return segments;
  }

  static bool _isTableHeader(List<String> lines, int index) {
    if (index >= lines.length ||
        !lines[index].trim().startsWith('|') ||
        !lines[index].trim().endsWith('|')) {
      return false;
    }

    if (index + 1 >= lines.length) {
      return false;
    }

    final nextLine = lines[index + 1].trim();
    return _isTableSeparator(nextLine);
  }

  static bool _isTableSeparator(String line) {
    if (!line.startsWith('|') || !line.endsWith('|')) {
      return false;
    }

    final content = line.substring(1, line.length - 1);
    return RegExp(r'^[\s\-:]+$').hasMatch(content) && content.contains('-');
  }

  static int minInt(int a, int b) => a < b ? a : b;
}
