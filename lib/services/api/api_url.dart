class ApiUrl {
  /// Broker apps list for blocking / GTT behaviour (GET, JSON).
  static const String tradingApps = 'trading-apps';

  static String loginUrl = "user/login";
  static String sendOtpUrl = "user/send-otp";
  static String verifyOtpUrl = "user/verify-otp";
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

  static const String getMessagesByUser = "messages/get-by-user";
  static const String gttAlertCreate = "gtt/alert/create";

  /// Confirms user deleted the trade in the broker app (form: trade_id, user_id).
  static const String deleteTrade = "delete/trade";

  /// Confirms user trailed the SL in the broker app (form: trade_id, user_id).
  static const String editTrade = "edit/trade";

  /// Confirms target hit / trade executed from chat button.
  static const String tradeExecuted = "trade/executed";
}
