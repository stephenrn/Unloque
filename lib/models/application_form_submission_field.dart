import 'package:unloque/models/program_form_field.dart';

class ApplicationSubmittedAttachment {
  final String name;
  final String downloadUrl;

  const ApplicationSubmittedAttachment({
    required this.name,
    required this.downloadUrl,
  });

  static ApplicationSubmittedAttachment? fromDynamic(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final name = map['name']?.toString() ?? '';
    final downloadUrl = map['downloadUrl']?.toString() ?? '';

    if (name.trim().isEmpty && downloadUrl.trim().isEmpty) return null;

    return ApplicationSubmittedAttachment(
      name: name,
      downloadUrl: downloadUrl,
    );
  }

  Map<String, dynamic> toPersistedMap() {
    return {
      'name': name,
      'downloadUrl': downloadUrl,
    };
  }
}

class ApplicationSubmittedFormField {
  final ProgramFormField definition;

  final String? answer;
  final String? selectedOption;
  final List<String> selectedOptions;
  final DateTime? selectedDate;
  final List<ApplicationSubmittedAttachment> files;

  const ApplicationSubmittedFormField({
    required this.definition,
    this.answer,
    this.selectedOption,
    this.selectedOptions = const <String>[],
    this.selectedDate,
    this.files = const <ApplicationSubmittedAttachment>[],
  });

  ProgramFormFieldType get type => definition.type;
  String get label => definition.label;

  static ApplicationSubmittedFormField? fromDynamic(dynamic value) {
    if (value is! Map) return null;

    final map = Map<String, dynamic>.from(value);
    final definition = ProgramFormField.fromMap(map);

    String? answer;
    String? selectedOption;
    List<String> selectedOptions = const <String>[];
    DateTime? selectedDate;
    List<ApplicationSubmittedAttachment> files =
        const <ApplicationSubmittedAttachment>[];

    switch (definition.type) {
      case ProgramFormFieldType.shortAnswer:
      case ProgramFormFieldType.paragraph:
        answer = map['answer']?.toString() ?? '';
        break;

      case ProgramFormFieldType.multipleChoice:
        final raw = map['selectedOption'];
        final text = raw?.toString();
        selectedOption = (text == null || text.trim().isEmpty) ? null : text;
        break;

      case ProgramFormFieldType.checkbox:
        if (map['selectedOptions'] is List) {
          selectedOptions = (map['selectedOptions'] as List)
              .map((e) => e.toString())
              .toList(growable: false);
        }
        break;

      case ProgramFormFieldType.date:
        final raw = map['selectedDate']?.toString();
        if (raw != null && raw.trim().isNotEmpty) {
          selectedDate = DateTime.tryParse(raw);
        }
        break;

      case ProgramFormFieldType.attachment:
        if (map['files'] is List) {
          files = (map['files'] as List)
              .map(ApplicationSubmittedAttachment.fromDynamic)
              .whereType<ApplicationSubmittedAttachment>()
              .toList(growable: false);
        }
        break;
    }

    return ApplicationSubmittedFormField(
      definition: definition,
      answer: answer,
      selectedOption: selectedOption,
      selectedOptions: selectedOptions,
      selectedDate: selectedDate,
      files: files,
    );
  }

  static List<ApplicationSubmittedFormField> listFromDynamic(dynamic raw) {
    if (raw is! List) return const <ApplicationSubmittedFormField>[];

    return raw
        .map(ApplicationSubmittedFormField.fromDynamic)
        .whereType<ApplicationSubmittedFormField>()
        .toList(growable: false);
  }
}
