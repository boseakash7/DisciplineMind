/// Package names of trading apps that can be blocked.
const List<String> blockedTradingAppPackages = [
  "com.zerodha.kite3", // Zerodha Kite
  "in.upstox.app", // Upstox
  "com.nextbillion.groww", // Groww
];

/// App labels for selection UI.
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

/// Apps that require expanded GTT form (GTT + SL + Target).
/// Add package names here to enable the 3-input popup for that app.
const Set<String> extendedGttInputPackages = {
  "com.nextbillion.groww",
};
