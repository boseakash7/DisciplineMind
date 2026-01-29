class InstrumentApiModel {
  String? status;
  List<Payload>? payload;

  InstrumentApiModel({this.status, this.payload});

  InstrumentApiModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['payload'] != null) {
      payload = <Payload>[];
      json['payload'].forEach((v) {
        payload!.add(Payload.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (payload != null) {
      data['payload'] = payload!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Payload {
  String? instrumentToken;
  String? exchangeToken;
  String? exchange;
  String? tradingsymbol;
  String? name;
  String? lastPrice;
  String? expiryDate;
  String? expiryTimezone;
  String? strike;
  String? tickSize;
  String? lotSize;
  String? instrumentType;
  String? segment;

  Payload({
    this.instrumentToken,
    this.exchangeToken,
    this.exchange,
    this.tradingsymbol,
    this.name,
    this.lastPrice,
    this.expiryDate,
    this.expiryTimezone,
    this.strike,
    this.tickSize,
    this.lotSize,
    this.instrumentType,
    this.segment,
  });

  Payload.fromJson(Map<String, dynamic> json) {
    instrumentToken = json['instrument_token'];
    exchangeToken = json['exchange_token'];
    exchange = json['exchange'];
    tradingsymbol = json['tradingsymbol'];
    name = json['name'];
    lastPrice = json['last_price'];
    expiryDate = json['expiry_date'];
    expiryTimezone = json['expiry_timezone'];
    strike = json['strike'];
    tickSize = json['tick_size'];
    lotSize = json['lot_size'];
    instrumentType = json['instrument_type'];
    segment = json['segment'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['instrument_token'] = instrumentToken;
    data['exchange_token'] = exchangeToken;
    data['exchange'] = exchange;
    data['tradingsymbol'] = tradingsymbol;
    data['name'] = name;
    data['last_price'] = lastPrice;
    data['expiry_date'] = expiryDate;
    data['expiry_timezone'] = expiryTimezone;
    data['strike'] = strike;
    data['tick_size'] = tickSize;
    data['lot_size'] = lotSize;
    data['instrument_type'] = instrumentType;
    data['segment'] = segment;
    return data;
  }
}
