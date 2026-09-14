class InstrumentDetailModel {
  String? status;
  InstrumentPayload? payload;

  InstrumentDetailModel({this.status, this.payload});

  InstrumentDetailModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    payload = json['payload'] != null
        ? InstrumentPayload.fromJson(json['payload'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    if (payload != null) {
      data['payload'] = payload!.toJson();
    }
    return data;
  }
}

//////////////////////////////////////////////////////////////

class InstrumentPayload {
  /// Dynamic instrument map
  Map<String, InstrumentData>? instruments;

  InstrumentPayload({this.instruments});

  InstrumentPayload.fromJson(Map<String, dynamic> json) {
    instruments = {};

    json.forEach((key, value) {
      instruments![key] = InstrumentData.fromJson(value);
    });
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (instruments != null) {
      instruments!.forEach((key, value) {
        data[key] = value.toJson();
      });
    }
    return data;
  }
}

//////////////////////////////////////////////////////////////

class InstrumentData {
  int? instrumentToken;
  Timestamp? timestamp;
  Timestamp? lastTradeTime;

  double? lastPrice;
  int? lastQuantity;
  int? buyQuantity;
  int? sellQuantity;
  int? volume;

  double? averagePrice;

  int? oi;
  int? oiDayHigh;
  int? oiDayLow;

  double? netChange;

  double? lowerCircuitLimit;
  double? upperCircuitLimit;

  Ohlc? ohlc;
  Depth? depth;

  InstrumentData({
    this.instrumentToken,
    this.timestamp,
    this.lastTradeTime,
    this.lastPrice,
    this.lastQuantity,
    this.buyQuantity,
    this.sellQuantity,
    this.volume,
    this.averagePrice,
    this.oi,
    this.oiDayHigh,
    this.oiDayLow,
    this.netChange,
    this.lowerCircuitLimit,
    this.upperCircuitLimit,
    this.ohlc,
    this.depth,
  });

  InstrumentData.fromJson(Map<String, dynamic> json) {
    instrumentToken = json['instrument_token'];

    timestamp = json['timestamp'] != null
        ? Timestamp.fromJson(json['timestamp'])
        : null;

    lastTradeTime = json['last_trade_time'] != null
        ? Timestamp.fromJson(json['last_trade_time'])
        : null;

    lastPrice = (json['last_price'] as num?)?.toDouble();
    lastQuantity = json['last_quantity'];

    buyQuantity = json['buy_quantity'];
    sellQuantity = json['sell_quantity'];

    volume = json['volume'];

    averagePrice = (json['average_price'] as num?)?.toDouble();

    oi = json['oi'];
    oiDayHigh = json['oi_day_high'];
    oiDayLow = json['oi_day_low'];

    netChange = (json['net_change'] as num?)?.toDouble();

    lowerCircuitLimit = (json['lower_circuit_limit'] as num?)?.toDouble();

    upperCircuitLimit = (json['upper_circuit_limit'] as num?)?.toDouble();

    ohlc = json['ohlc'] != null ? Ohlc.fromJson(json['ohlc']) : null;

    depth = json['depth'] != null ? Depth.fromJson(json['depth']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['instrument_token'] = instrumentToken;

    if (timestamp != null) {
      data['timestamp'] = timestamp!.toJson();
    }

    if (lastTradeTime != null) {
      data['last_trade_time'] = lastTradeTime!.toJson();
    }

    data['last_price'] = lastPrice;
    data['last_quantity'] = lastQuantity;

    data['buy_quantity'] = buyQuantity;
    data['sell_quantity'] = sellQuantity;

    data['volume'] = volume;

    data['average_price'] = averagePrice;

    data['oi'] = oi;
    data['oi_day_high'] = oiDayHigh;
    data['oi_day_low'] = oiDayLow;

    data['net_change'] = netChange;

    data['lower_circuit_limit'] = lowerCircuitLimit;
    data['upper_circuit_limit'] = upperCircuitLimit;

    if (ohlc != null) {
      data['ohlc'] = ohlc!.toJson();
    }

    if (depth != null) {
      data['depth'] = depth!.toJson();
    }

    return data;
  }
}

//////////////////////////////////////////////////////////////

class Timestamp {
  String? date;
  int? timezoneType;
  String? timezone;

  Timestamp({this.date, this.timezoneType, this.timezone});

  Timestamp.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    timezoneType = json['timezone_type'];
    timezone = json['timezone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['date'] = date;
    data['timezone_type'] = timezoneType;
    data['timezone'] = timezone;
    return data;
  }
}

//////////////////////////////////////////////////////////////

class Ohlc {
  double? open;
  double? high;
  double? low;
  double? close;

  Ohlc({this.open, this.high, this.low, this.close});

  Ohlc.fromJson(Map<String, dynamic> json) {
    open = (json['open'] as num?)?.toDouble();
    high = (json['high'] as num?)?.toDouble();
    low = (json['low'] as num?)?.toDouble();
    close = (json['close'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['open'] = open;
    data['high'] = high;
    data['low'] = low;
    data['close'] = close;
    return data;
  }
}

//////////////////////////////////////////////////////////////

class Depth {
  List<OrderBook>? buy;
  List<OrderBook>? sell;

  Depth({this.buy, this.sell});

  Depth.fromJson(Map<String, dynamic> json) {
    if (json['buy'] != null) {
      buy = (json['buy'] as List).map((v) => OrderBook.fromJson(v)).toList();
    }

    if (json['sell'] != null) {
      sell = (json['sell'] as List).map((v) => OrderBook.fromJson(v)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (buy != null) {
      data['buy'] = buy!.map((v) => v.toJson()).toList();
    }
    if (sell != null) {
      data['sell'] = sell!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

//////////////////////////////////////////////////////////////

class OrderBook {
  double? price;
  int? quantity;
  int? orders;

  OrderBook({this.price, this.quantity, this.orders});

  OrderBook.fromJson(Map<String, dynamic> json) {
    price = (json['price'] as num?)?.toDouble();
    quantity = json['quantity'];
    orders = json['orders'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['price'] = price;
    data['quantity'] = quantity;
    data['orders'] = orders;
    return data;
  }
}
