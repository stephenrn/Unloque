/// Lightweight compile-time config for external API keys.
///
/// Configure these via Flutter/Dart defines (recommended):
/// - `--dart-define=OPENAI_API_KEY=...`
/// - `--dart-define=OPENAI_MODEL=...` (optional)
/// - `--dart-define=OPENAI_BASE_URL=...` (optional)
/// - `--dart-define=OPENAI_ORG_ID=...` (optional)
/// - `--dart-define=OPENAI_PROJECT_ID=...` (optional)
///
/// Tip: You can also use `--dart-define-from-file=secrets.json`.
class APIKeys {
  static String getOpenAIKey() {
    return const String.fromEnvironment('OPENAI_API_KEY');
  }

  static String getOpenAIModel() {
    return const String.fromEnvironment(
      'OPENAI_MODEL',
      defaultValue: 'gpt-4o-mini',
    );
  }

  static String getOpenAIBaseUrl() {
    return const String.fromEnvironment(
      'OPENAI_BASE_URL',
      defaultValue: 'https://api.openai.com/v1',
    );
  }

  static String getOpenAIOrganizationId() {
    return const String.fromEnvironment('OPENAI_ORG_ID');
  }

  static String getOpenAIProjectId() {
    return const String.fromEnvironment('OPENAI_PROJECT_ID');
  }
}
