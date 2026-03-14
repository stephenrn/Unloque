enum ProgramFormFieldType {
  shortAnswer,
  paragraph,
  multipleChoice,
  checkbox,
  date,
  attachment,
}

ProgramFormFieldType programFormFieldTypeFromString(String value) {
  switch (value) {
    case 'short_answer':
      return ProgramFormFieldType.shortAnswer;
    case 'paragraph':
      return ProgramFormFieldType.paragraph;
    case 'multiple_choice':
      return ProgramFormFieldType.multipleChoice;
    case 'checkbox':
      return ProgramFormFieldType.checkbox;
    case 'date':
      return ProgramFormFieldType.date;
    case 'attachment':
      return ProgramFormFieldType.attachment;
    default:
      return ProgramFormFieldType.shortAnswer;
  }
}

String programFormFieldTypeToString(ProgramFormFieldType type) {
  switch (type) {
    case ProgramFormFieldType.shortAnswer:
      return 'short_answer';
    case ProgramFormFieldType.paragraph:
      return 'paragraph';
    case ProgramFormFieldType.multipleChoice:
      return 'multiple_choice';
    case ProgramFormFieldType.checkbox:
      return 'checkbox';
    case ProgramFormFieldType.date:
      return 'date';
    case ProgramFormFieldType.attachment:
      return 'attachment';
  }
}

class ProgramFormField {
  final String id;
  final ProgramFormFieldType type;
  final String label;
  final bool required;
  final List<String> options;
  final String? placeholder;

  const ProgramFormField({
    required this.id,
    required this.type,
    required this.label,
    required this.required,
    this.options = const <String>[],
    this.placeholder,
  });

  bool get supportsOptions =>
      type == ProgramFormFieldType.multipleChoice ||
      type == ProgramFormFieldType.checkbox;

  ProgramFormField copyWith({
    String? id,
    ProgramFormFieldType? type,
    String? label,
    bool? required,
    List<String>? options,
    String? placeholder,
  }) {
    return ProgramFormField(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      required: required ?? this.required,
      options: options ?? this.options,
      placeholder: placeholder ?? this.placeholder,
    );
  }

  static ProgramFormField fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    final id = rawId == null ? '' : rawId.toString();
    final type = programFormFieldTypeFromString(map['type']?.toString() ?? '');
    final label = map['label']?.toString() ?? '';
    final required = map['required'] == null ? true : map['required'] == true;
    final options = (map['options'] is List)
        ? (map['options'] as List)
            .map((e) => e.toString())
            .toList(growable: false)
        : const <String>[];
    final placeholder = map['placeholder']?.toString();

    return ProgramFormField(
      id: id,
      type: type,
      label: label,
      required: required,
      options: options,
      placeholder: placeholder,
    );
  }

  static List<ProgramFormField> listFromDynamic(dynamic raw) {
    if (raw is! List) return const <ProgramFormField>[];

    final result = <ProgramFormField>[];
    for (final item in raw) {
      if (item is ProgramFormField) {
        result.add(item);
      } else if (item is Map) {
        result.add(ProgramFormField.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    return result;
  }

  Map<String, dynamic> toPersistedMap() {
    final result = <String, dynamic>{
      'id': id,
      'type': programFormFieldTypeToString(type),
      'label': label,
      'required': required,
    };

    if (supportsOptions || options.isNotEmpty) {
      result['options'] = options;
    }

    if (placeholder != null && placeholder!.trim().isNotEmpty) {
      result['placeholder'] = placeholder;
    }

    return result;
  }
}
