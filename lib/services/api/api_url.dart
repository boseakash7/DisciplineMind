class ApiUrl {
  static String loginUrl = "user/login";
  static String searchInstrument = "instrument/search";
  static String getAlertsByUser = "alert/get-by-user-id";
  /// API to check if trading apps should stay blocked. Returns { "should_block": true/false }.
  /// Backend can use alerts or any logic. If endpoint missing, app falls back to getAlertsByUser.
  static String shouldBlockApps = "alert/should-block-apps";
  static String deleteAlert = "alert/delete";
  static String createAlertUrl = "alert/create";
  static String signUpUrl = "user/register";
  static String quoteUrl = "instrument/quote";

  static const String fcmSync = "fcm/sync";
}
