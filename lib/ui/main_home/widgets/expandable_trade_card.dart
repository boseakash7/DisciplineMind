import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/model/dmt_user_hit_trades_model.dart';
import 'package:flutter/material.dart';

/// Per-trade row in Trades tab — tap arrow to expand full hit/trade details.
class ExpandableTradeCard extends StatefulWidget {
  final String title;
  final String date;
  final bool profit;
  final String returnLabel;
  final DmtHitTrade? trade;

  const ExpandableTradeCard({
    super.key,
    required this.title,
    required this.date,
    required this.profit,
    required this.returnLabel,
    this.trade,
  });

  @override
  State<ExpandableTradeCard> createState() => _ExpandableTradeCardState();
}

class _ExpandableTradeCardState extends State<ExpandableTradeCard> {
  bool _expanded = false;

  static const _labelStyle = TextStyle(
    color: Color(0xCCFFFFFF),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const _valueStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  String _fmt(double? v) {
    if (v == null) return '—';
    if (v == v.truncateToDouble()) return v.truncate().toString();
    return v.toStringAsFixed(2);
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  Color _returnColor(double? value, {bool? positiveFallback}) {
    if (value != null) {
      return value >= 0 ? AppColors.primaryGreen : AppColors.actionRed;
    }
    if (positiveFallback != null) {
      return positiveFallback ? AppColors.primaryGreen : AppColors.actionRed;
    }
    return Colors.white.withOpacity(0.85);
  }

  Widget _returnText(
    String label,
    String value,
    double? rawValue, {
    bool? positiveFallback,
  }) {
    final valueColor = _returnColor(rawValue, positiveFallback: positiveFallback);

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, height: 1.25),
        children: [
          TextSpan(
            text: '$label - ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsRow() {
    final trade = widget.trade;
    final myValue = trade?.returnPercent;
    final mctValue = trade?.mctReturnPercentage;
    final myLabel = trade?.displayReturn ?? widget.returnLabel;
    final mctLabel = trade?.displayMctReturn ?? '—';

    return Wrap(
      spacing: 14,
      runSpacing: 2,
      children: [
        _returnText(
          'My Return',
          myLabel,
          myValue,
          positiveFallback: myValue == null && myLabel != '—' ? widget.profit : null,
        ),
        _returnText('MCT Return', mctLabel, mctValue),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.title.isNotEmpty ? widget.title[0].toUpperCase() : '',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Date - ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  formatTradeTabDate(widget.date),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _buildReturnsRow(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedDetails(),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.25))),
      ),
      child: widget.trade != null
          ? _apiTradeDetails(widget.trade!)
          : _fallbackDetails(),
    );
  }

  Widget _apiTradeDetails(DmtHitTrade t) {
    final d = t.trade;
    final entryPrice = d?.entryPrice ?? t.gttPrice;
    final stopLoss = d?.stopLoss ?? t.lowerPrice;
    final exitPrice = d?.takeProfit ?? t.upperPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Trade Name', t.displayExpandedTradeName, bottomPadding: 2),
        _detailRow('Trade Hit at', t.displayHitAt, bottomPadding: 2),
        _detailRow('Entry Price', _fmt(entryPrice), bottomPadding: 2),
        _detailRow('SL placed at', _fmt(stopLoss), bottomPadding: 2),
        _detailRow('Exit Price', _fmt(exitPrice), bottomPadding: 0),
        const SizedBox(height: 12),
        _detailRow('My Exit', t.displayMyExitDetail, bottomPadding: 2),
        _detailRow('MCT Exit', t.displayMctExitDetail, bottomPadding: 0),
      ],
    );
  }

  Widget _fallbackDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Name', widget.title),
        _detailRow('Date', formatTradeTabDate(widget.date)),
        _detailRow('Return', widget.returnLabel),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    double bottomPadding = 2,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 118, child: Text(label, style: _labelStyle)),
          Expanded(child: Text(value, style: _valueStyle)),
        ],
      ),
    );
  }
}
