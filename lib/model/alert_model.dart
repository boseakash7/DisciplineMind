class StockAlert {
  final String symbol;
  final String company;
  final double targetPrice;
  final double currentPrice;

  StockAlert({
    required this.symbol,
    required this.company,
    required this.targetPrice,
    required this.currentPrice,
  });
}
