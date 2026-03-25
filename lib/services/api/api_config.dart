class ApiConfig {
  static const String baseUrl = "http://api.disciplinedminds.in/api/";

  /// Base URL for messages/chat API (different domain)
  // static const String messagesBaseUrl = "http://disciplinedminds.in/";

  static Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
    // "Authorization": "Bearer YOUR_TOKEN",
  };
}
