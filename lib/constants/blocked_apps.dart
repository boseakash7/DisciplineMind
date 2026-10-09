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

/// iOS URL schemes and deep links per trading app package / broker name.
const Map<String, List<String>> iosTradingAppUrlSchemes = {
  // Groww
  "com.nextbillion.groww": [
    "groww://",
    "groww://app",
    "https://groww.in",
  ],
  "groww": [
    "groww://",
    "groww://app",
    "https://groww.in",
  ],
  // Zerodha Kite
  "com.zerodha.kite3": [
    "kite://",
    "zerodhakite://",
    "kite3://",
    "https://kite.zerodha.com",
  ],
  "zerodha": [
    "kite://",
    "zerodhakite://",
    "kite3://",
    "https://kite.zerodha.com",
  ],
  "kite": [
    "kite://",
    "zerodhakite://",
    "kite3://",
    "https://kite.zerodha.com",
  ],
  // Upstox
  "in.upstox.app": [
    "upstox://",
    "rksv://",
    "https://upstox.com",
  ],
  "upstox": [
    "upstox://",
    "rksv://",
    "https://upstox.com",
  ],
  // Angel One
  "com.msf.angelmobile": [
    "angelone://",
    "angelspark://",
    "spark://",
    "angelbroking://",
    "https://angelone.in",
  ],
  "angel one": [
    "angelone://",
    "angelspark://",
    "spark://",
    "angelbroking://",
    "https://angelone.in",
  ],
  "angel": [
    "angelone://",
    "angelspark://",
    "spark://",
    "angelbroking://",
    "https://angelone.in",
  ],
  // Dhan
  "co.dhan": [
    "dhan://",
    "dhanapp://",
    "https://dhan.co",
  ],
  "dhan": [
    "dhan://",
    "dhanapp://",
    "https://dhan.co",
  ],
  // Kotak Neo
  "com.kotak.neo": [
    "kotakneo://",
    "kotakstocktrader://",
    "https://www.kotaksecurities.com",
  ],
  "kotak neo": [
    "kotakneo://",
    "kotakstocktrader://",
    "https://www.kotaksecurities.com",
  ],
  "kotak": [
    "kotakneo://",
    "kotakstocktrader://",
    "https://www.kotaksecurities.com",
  ],
  // Paytm Money
  "com.paytmmoney": [
    "paytmmoney://",
    "https://www.paytmmoney.com",
  ],
  "paytm money": [
    "paytmmoney://",
    "https://www.paytmmoney.com",
  ],
  // INDmoney
  "com.indmoney": [
    "indmoney://",
    "https://www.indmoney.com",
  ],
  "indmoney": [
    "indmoney://",
    "https://www.indmoney.com",
  ],
  // ICICI Direct
  "com.icicidirect.mobile": [
    "icicidirect://",
    "https://www.icicidirect.com",
  ],
  "icici direct": [
    "icicidirect://",
    "https://www.icicidirect.com",
  ],
  // HDFC Securities / Sky
  "com.hdfcsec.trade": [
    "hdfcsec://",
    "hdfcsky://",
    "https://www.hdfcsec.com",
  ],
  "hdfc securities": [
    "hdfcsec://",
    "hdfcsky://",
    "https://www.hdfcsec.com",
  ],
  // Motilal Oswal
  "com.moti.moconnect": [
    "motilaloswal://",
    "moinvestor://",
    "https://www.motilaloswal.com",
  ],
  "motilal oswal": [
    "motilaloswal://",
    "moinvestor://",
    "https://www.motilaloswal.com",
  ],
  // SBI Securities
  "com.sbi.smartmobile": [
    "sbismart://",
    "https://www.sbismart.com",
  ],
  "sbi securities": [
    "sbismart://",
    "https://www.sbismart.com",
  ],
  // Sharekhan
  "com.sharekhan.corporate": [
    "sharekhan://",
    "https://www.sharekhan.com",
  ],
  "sharekhan": [
    "sharekhan://",
    "https://www.sharekhan.com",
  ],
  // Axis Direct
  "com.axis.direct": [
    "axisdirect://",
    "https://www.axisdirect.in",
  ],
  "axis direct": [
    "axisdirect://",
    "https://www.axisdirect.in",
  ],
  // IIFL
  "com.iifl.touch": [
    "iiflmarkets://",
    "https://www.iiflsecurities.com",
  ],
  "iifl": [
    "iiflmarkets://",
    "https://www.iiflsecurities.com",
  ],
};
