class ApiConfig {
  static const String baseUrl = "https://api.disciplinedminds.in/api/v2test/";

  /// Base URL for messages/chat API (different domain)
  // static const String messagesBaseUrl = "http://disciplinedminds.in/";

  static Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
    // "Authorization": "Bearer YOUR_TOKEN",
  };
}
