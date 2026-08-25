class V2ApiConfig {
  static const String baseUrl = "https://api.disciplinedminds.in/api/v2test/";

  static const String registerUrl = "user/register";
  static const String loginUrl = "user/login";
  static const String sendOtpUrl = "user/send-otp";
  static const String verifyOtpUrl = "user/verify-otp";
  static const String getMessagesByUser = "messages/get-by-user";
  static const String llmAsk = "llm/ask";

  static const String deleteTrade = "delete/trade";
  static const String editTrade = "edit/trade";
  static const String editGtt = "edit/gtt";
  static const String tradeExecuted = "trade/executed";
  static const String gttMissed = "trade/gtt-missed";

  static Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
  };
}
