/// Fallback labels (broker list + GTT behaviour come from API `trading-apps`).
const List<String> blockedTradingAppPackages = [
  "com.zerodha.kite3",
  "in.upstox.app",
  "com.nextbillion.groww",
];

/// App labels for legacy / native fallbacks only.
const Map<String, String> blockedTradingAppLabels = {
  "com.zerodha.kite3": "Zerodha Kite",
  "in.upstox.app": "Upstox",
  "com.nextbillion.groww": "Groww",
};

/// Optional launch aliases per selected app package.
/// We still respect "selected app only"; aliases are tried for that same app.
const Map<String, List<String>> tradingAppLaunchAliases = {
  "com.nextbillion.groww": ["com.nextbillion.groww", "com.groww.android"],
  "com.zerodha.kite3": ["com.zerodha.kite3", "com.zerodha.kite"],
  "in.upstox.app": ["in.upstox.app"],
};

/// Fallback when the trading-apps API has not loaded yet (`is_target` + `is_stoploss` drive GTT UI).
const Set<String> extendedGttInputPackages = {
  "com.nextbillion.groww",
};
