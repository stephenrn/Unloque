enum ResponseSectionType {
  paragraph,
  list,
  attachment,
}

ResponseSectionType responseSectionTypeFromString(String value) {
  switch (value) {
    case 'paragraph':
      return ResponseSectionType.paragraph;
    case 'list':
      return ResponseSectionType.list;
    case 'attachment':
      return ResponseSectionType.attachment;
    default:
      return ResponseSectionType.paragraph;
  }
}

String responseSectionTypeToString(ResponseSectionType type) {
  switch (type) {
    case ResponseSectionType.paragraph:
      return 'paragraph';
    case ResponseSectionType.list:
      return 'list';
    case ResponseSectionType.attachment:
      return 'attachment';
  }
}

class ResponseAttachmentFile {
  final String name;
  final String? downloadUrl;
  final String? localPath;
  final bool isPending;
  final String? uploadedAt;

  const ResponseAttachmentFile({
    required this.name,
    this.downloadUrl,
    this.localPath,
    this.isPending = false,
    this.uploadedAt,
  });

  ResponseAttachmentFile copyWith({
    String? name,
    String? downloadUrl,
    String? localPath,
    bool? isPending,
    String? uploadedAt,
  }) {
    return ResponseAttachmentFile(
      name: name ?? this.name,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      localPath: localPath ?? this.localPath,
      isPending: isPending ?? this.isPending,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  factory ResponseAttachmentFile.fromMap(Map<String, dynamic> map) {
    return ResponseAttachmentFile(
      name: (map['name'] ?? '').toString(),
      downloadUrl: map['downloadUrl']?.toString(),
      localPath: map['path']?.toString() ?? map['localPath']?.toString(),
      isPending: map['isPending'] == true,
      uploadedAt: map['uploadedAt']?.toString(),
    );
  }

  /// Shape persisted to Firestore (does not include localPath/isPending).
  Map<String, dynamic> toPersistedMap() {
    return {
      'name': name,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (uploadedAt != null) 'uploadedAt': uploadedAt,
    };
  }

  /// Shape used by UI while editing.
  Map<String, dynamic> toEditorMap() {
    return {
      'name': name,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (localPath != null) 'path': localPath,
      if (uploadedAt != null) 'uploadedAt': uploadedAt,
      if (isPending) 'isPending': true,
    };
  }
}

sealed class ResponseSection {
  final String id;
  final ResponseSectionType type;
  final String label;

  const ResponseSection({
    required this.id,
    required this.type,
    required this.label,
  });

  ResponseSection copyWith({String? label});

  /// Shape persisted to Firestore.
  Map<String, dynamic> toPersistedMap();

  factory ResponseSection.fromMap(Map<String, dynamic> map) {
    final type = responseSectionTypeFromString((map['type'] ?? '').toString());
    final id = (map['id'] ?? '').toString();
    final label = (map['label'] ?? '').toString();

    switch (type) {
      case ResponseSectionType.paragraph:
        return ParagraphResponseSection(
          id: id,
          label: label,
          content: (map['content'] ?? '').toString(),
        );
      case ResponseSectionType.list:
        return ListResponseSection(
          id: id,
          label: label,
          items: List<String>.from(map['items'] ?? const <String>[]),
        );
      case ResponseSectionType.attachment:
        final files = (map['files'] as List?)
                ?.whereType<Map>()
                .map((m) => ResponseAttachmentFile.fromMap(
                      Map<String, dynamic>.from(m),
                    ))
                .toList() ??
            const <ResponseAttachmentFile>[];

        return AttachmentResponseSection(
          id: id,
          label: label,
          files: files,
        );
    }
  }

  static List<ResponseSection> listFromDynamic(dynamic raw) {
    if (raw is! List) return const <ResponseSection>[];

    final result = <ResponseSection>[];
    for (final item in raw) {
      if (item is ResponseSection) {
        result.add(item);
      } else if (item is Map) {
        result.add(ResponseSection.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    return result;
  }
}

class ParagraphResponseSection extends ResponseSection {
  final String content;

  const ParagraphResponseSection({
    required super.id,
    required super.label,
    this.content = '',
  }) : super(type: ResponseSectionType.paragraph);

  @override
  ParagraphResponseSection copyWith({String? label, String? content}) {
    return ParagraphResponseSection(
      id: id,
      label: label ?? this.label,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, dynamic> toPersistedMap() {
    return {
      'id': id,
      'type': responseSectionTypeToString(type),
      'label': label,
      'content': content,
    };
  }
}

class ListResponseSection extends ResponseSection {
  final List<String> items;

  const ListResponseSection({
    required super.id,
    required super.label,
    required this.items,
  }) : super(type: ResponseSectionType.list);

  @override
  ListResponseSection copyWith({String? label, List<String>? items}) {
    return ListResponseSection(
      id: id,
      label: label ?? this.label,
      items: items ?? this.items,
    );
  }

  @override
  Map<String, dynamic> toPersistedMap() {
    return {
      'id': id,
      'type': responseSectionTypeToString(type),
      'label': label,
      'items': items,
    };
  }
}

class AttachmentResponseSection extends ResponseSection {
  final List<ResponseAttachmentFile> files;

  const AttachmentResponseSection({
    required super.id,
    required super.label,
    required this.files,
  }) : super(type: ResponseSectionType.attachment);

  @override
  AttachmentResponseSection copyWith({
    String? label,
    List<ResponseAttachmentFile>? files,
  }) {
    return AttachmentResponseSection(
      id: id,
      label: label ?? this.label,
      files: files ?? this.files,
    );
  }

  @override
  Map<String, dynamic> toPersistedMap() {
    return {
      'id': id,
      'type': responseSectionTypeToString(type),
      'label': label,
      'files': files.map((f) => f.toPersistedMap()).toList(growable: false),
    };
  }
}
