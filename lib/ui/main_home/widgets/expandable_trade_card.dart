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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Alert'),
        _detailRow('Alert ID', '${t.alertId}'),
        _detailRow('Trade ID', '${t.tradeId}'),
        _detailRow('Exchange', t.exchange),
        _detailRow('Symbol', t.tradingsymbol),
        _detailRow('Status', t.status),
        _detailRow('Hit type', t.hitType),
        _detailRow('Hit price', _fmt(t.hitPrice)),
        _detailRow('Hit at', t.hitAtFormatted),
        _detailRow('Created at', t.createdAtFormatted),
        _detailRow('Current price', _fmt(t.currentPrice)),
        _detailRow('Upper price', _fmt(t.upperPrice)),
        _detailRow('Lower price', _fmt(t.lowerPrice)),
        _detailRow('GTT price', _fmt(t.gttPrice)),
        if (d != null) ...[
          const SizedBox(height: 10),
          const _SectionTitle('Trade'),
          _detailRow('Name', d.name),
          _detailRow('Header', d.header),
          _detailRow('Symbol', d.symbol),
          _detailRow('Trade UID', d.tradeUid),
          _detailRow('Direction', d.direction),
          _detailRow('Entry price', _fmt(d.entryPrice)),
          _detailRow('Stop loss', _fmt(d.stopLoss)),
          _detailRow('Take profit', _fmt(d.takeProfit)),
          _detailRow('Current price', _fmt(d.currentPrice)),
          _detailRow('Status', d.status),
        ],
      ],
    );
  }

  Widget _fallbackDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Trade details'),
        _detailRow('Instrument', widget.title),
        _detailRow('Date', widget.date),
        _detailRow('Return', widget.returnLabel),
        _detailRow('Exchange', 'NSE'),
        _detailRow('Status', 'completed'),
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

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
