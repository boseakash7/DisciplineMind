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
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(2);

  void _toggle() => setState(() => _expanded = !_expanded);

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
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
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
                                  widget.date,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Return',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.returnLabel,
                          style: TextStyle(
                            color: widget.profit
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 5),
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
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
      ),
      child: widget.trade != null
          ? _apiTradeDetails(widget.trade!)
          : _fallbackDetails(),
    );
  }

  Widget _apiTradeDetails(DmtHitTrade t) {
    final d = t.trade;
    final name = d?.name.trim() ?? '';
    final exchange = (d?.exchange ?? t.exchange).trim();
    final nameWithExchange = name.isNotEmpty
        ? (exchange.isNotEmpty ? '$name ($exchange)' : name)
        : (exchange.isNotEmpty ? exchange : t.tradingsymbol);
    final entryPrice = d?.entryPrice ?? t.gttPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Name', nameWithExchange),
        _detailRow('Symbol', t.tradingsymbol),
        _detailRow('Hit price', _fmt(t.hitPrice)),
        _detailRow('Hit at', t.hitAtFormatted),
        _detailRow('Created at', t.createdAtFormatted),
        _detailRow('Target price', _fmt(t.upperPrice)),
        _detailRow('Stop loss', _fmt(t.lowerPrice)),
        _detailRow('Entry price', _fmt(entryPrice)),
      ],
    );
  }

  Widget _fallbackDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Name', widget.title),
        _detailRow('Date', widget.date),
        _detailRow('Return', widget.returnLabel),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 108, child: Text(label, style: _labelStyle)),
          Expanded(child: Text(value, style: _valueStyle)),
        ],
      ),
    );
  }
}
