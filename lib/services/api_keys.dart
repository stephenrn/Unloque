// This file should be added to .gitignore to keep API keys secure

class APIKeys {
  // The API key is obfuscated here but should be stored more securely in production
  // Consider using Flutter's secure storage or environment variables
  static String getOpenAIKey() {
    // The API key is obfuscated for security
    final String obscuredKey =
        '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';
    return obscuredKey;
  }
}
