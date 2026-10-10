/// Fallback labels (broker list + GTT behaviour come from API `trading-apps`).
const List<String> blockedTradingAppPackages = [
  "com.nextbillion.groww",
  "com.zerodha.kite3",
  "com.msf.angelmobile",
  "com.icicidirect.mobile",
  "in.upstox.app",
  "com.kotak.neo",
  "com.hdfcsec.trade",
  "com.sbi.smart",
  "co.dhan",
  "com.motilaloswal.moinvestor",
  "com.paytmmoney",
  "in.indwealth",
  "com.sharekhan",
  "com.axis.direct",
  "com.indiainfoline",
  "com.fivepaisa.trade",
  "com.choicebroking.jiffy",
  "com.geojit.selfie",
  "com.mshare",
  "com.sahi.app",
];

/// App labels for legacy / native fallbacks only.
const Map<String, String> blockedTradingAppLabels = {
  "com.nextbillion.groww": "Groww",
  "com.zerodha.kite3": "Zerodha Kite",
  "com.msf.angelmobile": "Angel One",
  "com.icicidirect.mobile": "ICICI Direct",
  "in.upstox.app": "Upstox",
  "com.kotak.neo": "Kotak Neo",
  "com.hdfcsec.trade": "HDFC Securities",
  "com.sbi.smart": "SBI Securities",
  "co.dhan": "Dhan",
  "com.motilaloswal.moinvestor": "Motilal Oswal",
  "com.paytmmoney": "Paytm Money",
  "in.indwealth": "INDmoney",
  "com.sharekhan": "Sharekhan",
  "com.axis.direct": "Axis Securities",
  "com.indiainfoline": "IIFL Securities",
  "com.fivepaisa.trade": "5paisa",
  "com.choicebroking.jiffy": "Choice",
  "com.geojit.selfie": "Geojit",
  "com.mshare": "Mirae Asset",
  "com.sahi.app": "Sahi",
};

/// Optional launch aliases per selected app package.
/// We still respect "selected app only"; aliases are tried for that same app.
const Map<String, List<String>> tradingAppLaunchAliases = {
  "com.nextbillion.groww": ["com.nextbillion.groww", "com.groww.android"],
  "com.zerodha.kite3": ["com.zerodha.kite3", "com.zerodha.kite"],
  "com.msf.angelmobile": ["com.msf.angelmobile"],
  "com.icicidirect.mobile": ["com.icicidirect.mobile"],
  "in.upstox.app": ["in.upstox.app"],
  "com.kotak.neo": ["com.kotak.neo"],
  "com.hdfcsec.trade": ["com.hdfcsec.trade", "com.hdfcsec.investright"],
  "com.sbi.smart": ["com.sbi.smart", "com.sbicap.sbismart"],
  "co.dhan": ["co.dhan"],
  "com.motilaloswal.moinvestor": ["com.motilaloswal.moinvestor", "com.motilaloswal.rise"],
  "com.paytmmoney": ["com.paytmmoney"],
  "in.indwealth": ["in.indwealth", "com.indwealth"],
  "com.sharekhan": ["com.sharekhan"],
  "com.axis.direct": ["com.axis.direct"],
  "com.indiainfoline": ["com.indiainfoline"],
  "com.fivepaisa.trade": ["com.fivepaisa.trade"],
  "com.choicebroking.jiffy": ["com.choicebroking.jiffy", "com.choiceequitybroking.jiffy"],
  "com.geojit.selfie": ["com.geojit.selfie"],
  "com.mshare": ["com.mshare", "com.mstock"],
  "com.sahi.app": ["com.sahi.app", "com.sahi.invest"],
};

/// Fallback when the trading-apps API has not loaded yet (`is_target` + `is_stoploss` drive GTT UI).
const Set<String> extendedGttInputPackages = {
  "com.nextbillion.groww",
};

/// Custom URL schemes for launching trading apps on iOS.
const Map<String, List<String>> iosTradingAppSchemes = {
  "com.nextbillion.groww": ["groww://"],
  "com.zerodha.kite3": ["kite://", "zerodha://"],
  "com.msf.angelmobile": ["angelone://", "angelbroking://", "angelmobile://"],
  "com.icicidirect.mobile": ["icicidirect://", "icicidirectmobile://"],
  "in.upstox.app": ["upstox://"],
  "com.kotak.neo": ["kotakneo://", "kotakstocktrader://"],
  "com.hdfcsec.trade": ["hdfcsec://", "hdfcsky://"],
  "com.sbi.smart": ["sbismart://"],
  "co.dhan": ["dhan://"],
  "com.motilaloswal.moinvestor": ["moinvestor://", "motilaloswal://"],
  "com.paytmmoney": ["paytmmoney://"],
  "in.indwealth": ["indmoney://", "indwealth://"],
  "com.sharekhan": ["sharekhan://"],
  "com.axis.direct": ["axisdirect://"],
  "com.indiainfoline": ["iifl://"],
  "com.fivepaisa.trade": ["5paisa://"],
  "com.choicebroking.jiffy": ["jiffy://"],
  "com.geojit.selfie": ["geojitselfie://"],
  "com.mshare": ["mstock://"],
  "com.sahi.app": ["sahiapp://"],
};
