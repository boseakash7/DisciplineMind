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
