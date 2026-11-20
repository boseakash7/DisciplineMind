/// Fallback labels (broker list + GTT behaviour come from API `trading-apps`).
const List<String> blockedTradingAppPackages = [
  "com.nextbillion.groww",
  "com.zerodha.kite3",
  "com.msf.angelmobile",
  "com.icicidirect.idirectsuper",
  "in.upstox.app",
  "com.kotak.neo",
  "com.hsl.investright",
  "com.msf.sbicap.securities",
  "com.dhan.live",
  "com.mosl.mobile",
  "com.paytmmoney",
  "in.indwealth",
  "com.sharekhan.androidsharemobile",
  "com.axisdirect.invest",
  "com.indiainfoline",
  "com.fivepaisa.trade",
  "com.choiceequitybroking.jiffy",
  "com.geojit.flip_mobile",
  "com.rs.mirae",
  "com.aaritya.sahi_trade_app",
];

/// App labels for legacy / native fallbacks only.
const Map<String, String> blockedTradingAppLabels = {
  "com.nextbillion.groww": "Groww",
  "com.zerodha.kite3": "Zerodha Kite",
  "com.msf.angelmobile": "Angel One",
  "com.icicidirect.idirectsuper": "ICICI Direct",
  "in.upstox.app": "Upstox",
  "com.kotak.neo": "Kotak Neo",
  "com.hsl.investright": "HDFC Securities",
  "com.msf.sbicap.securities": "SBI Securities",
  "com.dhan.live": "Dhan",
  "com.mosl.mobile": "Motilal Oswal",
  "com.paytmmoney": "Paytm Money",
  "in.indwealth": "INDmoney",
  "com.sharekhan.androidsharemobile": "Sharekhan",
  "com.axisdirect.invest": "Axis Securities",
  "com.indiainfoline": "IIFL Securities",
  "com.fivepaisa.trade": "5paisa",
  "com.choiceequitybroking.jiffy": "Choice",
  "com.geojit.flip_mobile": "Geojit",
  "com.rs.mirae": "Mirae Asset",
  "com.aaritya.sahi_trade_app": "Sahi",
};

/// Optional launch aliases per selected app package.
/// We still respect "selected app only"; aliases are tried for that same app.
const Map<String, List<String>> tradingAppLaunchAliases = {
  "com.nextbillion.groww": ["com.nextbillion.groww", "com.groww.android"],
  "com.zerodha.kite3": ["com.zerodha.kite3", "com.zerodha.kite"],
  "com.msf.angelmobile": ["com.msf.angelmobile"],
  "com.icicidirect.idirectsuper": ["com.icicidirect.idirectsuper"],
  "in.upstox.app": ["in.upstox.app"],
  "com.kotak.neo": ["com.kotak.neo"],
  // HDFC Sky is the broker's newer app; try it when InvestRight is absent.
  "com.hsl.investright": ["com.hsl.investright", "com.cloudtradetech.sky"],
  "com.msf.sbicap.securities": ["com.msf.sbicap.securities"],
  "com.dhan.live": ["com.dhan.live"],
  "com.mosl.mobile": ["com.mosl.mobile", "com.mosl.research360app"],
  "com.paytmmoney": ["com.paytmmoney"],
  "in.indwealth": ["in.indwealth", "com.indwealth"],
  "com.sharekhan.androidsharemobile": ["com.sharekhan.androidsharemobile"],
  // Orbit is Axis Direct's trading terminal, Investor is the retail app.
  "com.axisdirect.invest": ["com.axisdirect.invest", "com.axisdirect.orbit"],
  "com.indiainfoline": ["com.indiainfoline"],
  "com.fivepaisa.trade": ["com.fivepaisa.trade"],
  "com.choiceequitybroking.jiffy": [
    "com.choiceequitybroking.jiffy",
    "com.choicebroking.choiceconnect",
  ],
  "com.geojit.flip_mobile": ["com.geojit.flip_mobile", "com.geojit.myg"],
  "com.rs.mirae": ["com.rs.mirae"],
  "com.aaritya.sahi_trade_app": ["com.aaritya.sahi_trade_app"],
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
  "com.icicidirect.idirectsuper": ["icicidirect://", "icicidirectmobile://"],
  "in.upstox.app": ["upstox://"],
  "com.kotak.neo": ["kotakneo://", "kotakstocktrader://"],
  "com.hsl.investright": ["hdfcsec://", "hdfcsky://"],
  "com.msf.sbicap.securities": ["sbismart://"],
  "com.dhan.live": ["dhan://"],
  "com.mosl.mobile": ["moinvestor://", "motilaloswal://"],
  "com.paytmmoney": ["paytmmoney://"],
  "in.indwealth": ["indmoney://", "indwealth://"],
  "com.sharekhan.androidsharemobile": ["sharekhan://"],
  "com.axisdirect.invest": ["axisdirect://"],
  "com.indiainfoline": ["iifl://"],
  "com.fivepaisa.trade": ["5paisa://"],
  "com.choiceequitybroking.jiffy": ["jiffy://"],
  "com.geojit.flip_mobile": ["geojitselfie://"],
  "com.rs.mirae": ["mstock://"],
  "com.aaritya.sahi_trade_app": ["sahiapp://"],
};

/// App Store URLs for fallback when trading app is not installed.
const Map<String, String> iosAppStoreUrls = {
  "com.zerodha.kite3": "https://apps.apple.com/in/app/kite-by-zerodha/id1449453802",
  "com.nextbillion.groww": "https://apps.apple.com/in/app/groww-stocks-mutual-fund-ipo/id1404871703",
  "in.upstox.app": "https://apps.apple.com/in/app/upstox-stocks-mf-options/id6443944636",
  "com.msf.angelmobile": "https://apps.apple.com/in/app/angel-one-stocks-mutual-fund/id1060530986",
  "com.dhan.live": "https://apps.apple.com/in/app/dhan-stock-market-trading-app/id1575318726",
  "com.kotak.neo": "https://apps.apple.com/in/app/kotak-neo-stock-trading-app/id1593676542",
  "com.paytmmoney": "https://apps.apple.com/in/app/paytm-money-stocks-mutual-funds/id1344445880",
  "com.icicidirect.idirectsuper": "https://apps.apple.com/in/app/icicidirect-markets-stocks/id1566265737",
  "com.hsl.investright": "https://apps.apple.com/in/app/hdfc-sky-stock-market-invest/id6448375631",
};
